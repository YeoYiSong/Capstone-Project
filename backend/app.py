from flask import Flask, request, jsonify, render_template, session, Response, stream_with_context
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime
from flask_session import Session
import requests
import contextlib
import chromadb
import re

app = Flask(__name__,)
CORS(app, supports_credentials=True)

app.config['SECRET_KEY'] = 'replace_with_your_own_secret_key'
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)
db_config = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '',
    'database': 'sd'
}


# --- 初始化 ChromaDB 向量資料庫 ---
client = chromadb.PersistentClient(path=r"d:/大四專題/oil/oilmodule/backend/chroma_db")#需更改位置
col = client.get_or_create_collection(name="essential_oils")

# --- LLM API 參數 ---
OLLAMA_CHAT_URL = 'http://localhost:11434/api/chat'
OLLAMA_EMBED_URL = 'http://localhost:11434/api/embed'
EMBED_MODEL = 'nn200433/text2vec-bge-large-chinese'

def get_db_connection():
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

@app.before_request
def log_request_info():
    print(f"[請求] {request.method} {request.url}")

@app.route('/get_user_id', methods=['POST'])
def get_user_id():
    print("[路由] 收到 /get_user_id 請求")
    data = request.get_json()
    print(f"[路由] 傳入資料： {data}")

    firebase_uid = data.get('firebase_uid')
    if not firebase_uid:
        return jsonify({'error': 'Missing firebase_uid'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = """
            SELECT users.id AS user_id
            FROM users
            JOIN auth_users ON users.auth_user_id = auth_users.id
            WHERE auth_users.firebase_uid = %s
        """
        cursor.execute(query, (firebase_uid,))
        result = cursor.fetchone()

        if result:
            user_id = result['user_id']
            print(f"[路由] 找到了 user_id：{result['user_id']}")
            session["user_id"] = user_id
            return jsonify({'user_id': user_id}), 200
        else:
            print("[路由] 找不到對應的 user，準備自動創建")
            insert_auth = "INSERT INTO auth_users (firebase_uid) VALUES (%s)"
            cursor.execute(insert_auth, (firebase_uid,))
            auth_user_id = cursor.lastrowid
            insert_user = "INSERT INTO users (auth_user_id) VALUES (%s)"
            cursor.execute(insert_user, (auth_user_id,))
            user_id = cursor.lastrowid
            connection.commit()
            print(f"[路由] 自動新增 user_id：{user_id}")
            session["user_id"] = user_id
            return jsonify({'user_id': user_id}), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch/create user id: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/register_user_if_not_exists', methods=['POST'])
def register_user_if_not_exists():
    data = request.get_json()
    firebase_uid = data.get('firebase_uid')
    if not firebase_uid:
        return jsonify({'error': 'Missing firebase_uid'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id FROM auth_users WHERE firebase_uid = %s", (firebase_uid,))
        auth_user = cursor.fetchone()

        if not auth_user:
            cursor.execute("INSERT INTO auth_users (firebase_uid) VALUES (%s)", (firebase_uid,))
            auth_user_id = cursor.lastrowid
            cursor.execute("INSERT INTO users (auth_user_id) VALUES (%s)", (auth_user_id,))
            user_id = cursor.lastrowid
            connection.commit()
        else:
            cursor.execute("SELECT id FROM users WHERE auth_user_id = %s", (auth_user["id"],))
            user = cursor.fetchone()
            user_id = user["id"] if user else None

        return jsonify({'user_id': user_id}), 200
    except Error as e:
        return jsonify({'error': f'Registration failed: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

# 日記模組
@app.route('/save_diary_entry', methods=['POST'])
def save_diary_entry():
    data = request.get_json()
    user_id = session.get('user_id')
    date = data.get('date')
    type = data.get('type')
    emotions = data.get('emotions')
    mixed_color = data.get('mixed_color')
    mood_text = data.get('mood_text')
    details = data.get('details')
    is_english = data.get('is_english', False)

    if not user_id or not date or not type or not emotions:
        return jsonify({'error': 'Missing required fields'}), 400
    if type not in ['Moment', 'Day']:
        return jsonify({'error': 'Invalid entry type'}), 400

    # 映射情緒
    emotion_map = {
        '快樂': 'joy', 'joy': 'joy',
        '悲傷': 'sadness', 'sadness': 'sadness',
        '憤怒': 'anger', 'anger': 'anger',
        '積極': 'positive', 'positive': 'positive',
        '焦慮': 'anxiety', 'anxiety': 'anxiety',
        '疲憊': 'exhaust', 'exhaust': 'exhaust'
    }
    emotion_values = {'joy': 0, 'sadness': 0, 'anger': 0, 'positive': 0, 'anxiety': 0, 'exhaust': 0}
    for emotion in emotions:
        emotion_name = emotion.get('emotion')
        intensity = float(emotion.get('intensity', 0))
        if emotion_name in emotion_map:
            emotion_values[emotion_map[emotion_name]] = intensity

    try:
        create_at = datetime.fromisoformat(date.replace('Z', '+00:00')).strftime('%Y-%m-%d %H:%M:%S')
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor()
        if type == 'Day':
            query = """
            INSERT INTO diaries (user_id, content, joy, sadness, anger, positive, anxiety, exhaust, color_mix, create_at, is_english, details)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(query, (
                user_id,
                mood_text or '',
                emotion_values['joy'],
                emotion_values['sadness'],
                emotion_values['anger'],
                emotion_values['positive'],
                emotion_values['anxiety'],
                emotion_values['exhaust'],
                mixed_color,
                create_at,
                is_english,
                details or ''
            ))
        else:  # Moment
            query = """
            INSERT INTO now (user_id, note, joy, sadness, anger, positive, anxiety, exhaust, create_at, is_english, details)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(query, (
                user_id,
                mood_text or '',
                emotion_values['joy'],
                emotion_values['sadness'],
                emotion_values['anger'],
                emotion_values['positive'],
                emotion_values['anxiety'],
                emotion_values['exhaust'],
                create_at,
                is_english,
                details or ''
            ))
        connection.commit()
        return jsonify({'message': 'Diary entry saved successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to save diary entry: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/get_diary_entries/<date>', methods=['GET'])
def get_diary_entries(date):
    user_id = session.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    try:
        entry_date = datetime.strptime(date, '%Y-%m-%d').date().isoformat()
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query_diaries = """
        SELECT id, user_id, content AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
            color_mix AS mixed_color, create_at, is_english, details
        FROM diaries WHERE user_id = %s AND DATE(create_at) = %s
        """
        cursor.execute(query_diaries, (user_id, entry_date))
        day_entries = cursor.fetchall()

        query_now = """
        SELECT id, user_id, note AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
            NULL AS mixed_color, create_at, is_english, details
        FROM now WHERE user_id = %s AND DATE(create_at) = %s
        """
        cursor.execute(query_now, (user_id, entry_date))
        moment_entries = cursor.fetchall()

        entries = day_entries + moment_entries
        for entry in entries:
            entry['entry_type'] = 'Day' if entry['mixed_color'] is not None else 'Moment'
            entry['entry_date'] = entry['create_at'].date().isoformat()
            entry['entry_time'] = entry['create_at'].strftime('%H:%M:%S')
            entry['emotions'] = [
                {'emotion': '快樂' if not entry['is_english'] else 'joy', 'intensity': float(entry['joy'])},
                {'emotion': '悲傷' if not entry['is_english'] else 'sadness', 'intensity': float(entry['sadness'])},
                {'emotion': '憤怒' if not entry['is_english'] else 'anger', 'intensity': float(entry['anger'])},
                {'emotion': '積極' if not entry['is_english'] else 'positive', 'intensity': float(entry['positive'])},
                {'emotion': '焦慮' if not entry['is_english'] else 'anxiety', 'intensity': float(entry['anxiety'])},
                {'emotion': '疲憊' if not entry['is_english'] else 'exhaust', 'intensity': float(entry['exhaust'])}
            ]
            for field in ['joy', 'sadness', 'anger', 'positive', 'anxiety', 'exhaust']:
                del entry[field]

        return jsonify(entries), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch diary entries: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/get_all_diary_entries', methods=['GET'])
def get_all_diary_entries():
    user_id = session.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query_diaries = """
        SELECT id, user_id, content AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
               color_mix AS mixed_color, create_at, is_english, details
        FROM diaries WHERE user_id = %s
        """
        cursor.execute(query_diaries, (user_id,))
        day_entries = cursor.fetchall()

        query_now = """
        SELECT id, user_id, note AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
               NULL AS mixed_color, create_at, is_english, details
        FROM now WHERE user_id = %s
        """
        cursor.execute(query_now, (user_id,))
        moment_entries = cursor.fetchall()

        entries = day_entries + moment_entries
        for entry in entries:
            entry['entry_type'] = 'Day' if entry['mixed_color'] is not None else 'Moment'
            entry['entry_date'] = entry['create_at'].date().isoformat()
            entry['entry_time'] = entry['create_at'].strftime('%H:%M:%S')
            entry['emotions'] = [
                {'emotion': '快樂' if not entry['is_english'] else 'joy', 'intensity': float(entry['joy'])},
                {'emotion': '悲傷' if not entry['is_english'] else 'sadness', 'intensity': float(entry['sadness'])},
                {'emotion': '憤怒' if not entry['is_english'] else 'anger', 'intensity': float(entry['anger'])},
                {'emotion': '積極' if not entry['is_english'] else 'positive', 'intensity': float(entry['positive'])},
                {'emotion': '焦慮' if not entry['is_english'] else 'anxiety', 'intensity': float(entry['anxiety'])},
                {'emotion': '疲憊' if not entry['is_english'] else 'exhaust', 'intensity': float(entry['exhaust'])}
            ]
            for field in ['joy', 'sadness', 'anger', 'positive', 'anxiety', 'exhaust']:
                del entry[field]

        return jsonify(entries), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch diary entries: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

# 呼吸模組
@app.route('/breath_record', methods=['POST'])
def add_breath_record():
    data = request.get_json()
    user_id = session.get('user_id')
    duration = data.get('duration')
    min_value = data.get('min')
    feeling = data.get('feeling')
    type_value = data.get('type', '引導')

    if not user_id or min_value is None:
        return jsonify({'error': 'Missing required fields: user_id or min'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor()
        query = """
            INSERT INTO breath_record (user_id, duration, min, feeling, type)
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (user_id, duration, min_value, feeling, type_value))
        connection.commit()
        return jsonify({'message': 'Breath record saved successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to save breath record: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/breath_record/<date>', methods=['GET'])
def get_breath_records_by_date(date):
    user_id = session.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing or invalid user_id'}), 400

    try:
        entry_date = datetime.strptime(date, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Date must be YYYY-MM-DD'}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        sql = (
            "SELECT  id, "
            "        user_id, "
            "        duration, "
            "        min, "
            "        feeling, "
            "        type, "
            "        create_at "
            "FROM    breath_record "
            "WHERE   user_id = %s "
            "  AND   DATE(create_at) = %s "
            "ORDER BY create_at ASC"
        )
        with contextlib.closing(conn.cursor(dictionary=True)) as cur:
            cur.execute(sql, (user_id, entry_date))
            rows = cur.fetchall()

        for r in rows:
            r['record_date'] = r['create_at'].date().isoformat()
            r['record_time'] = r['create_at'].strftime('%H:%M:%S')
            r['create_at'] = r['create_at'].isoformat()

        return jsonify(rows), 200
    except Error as e:
        app.logger.exception('Failed to fetch breath records')
        return jsonify({'error': f'Failed to fetch breath records: {e}'}), 500
    finally:
        conn.close()

@app.route('/breath_record/user/<user_id>', methods=['GET'])
def get_breath_records_by_user(user_id):
    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = "SELECT * FROM breath_record WHERE user_id = %s"
        cursor.execute(query, (user_id,))
        records = cursor.fetchall()

        for r in records:
            if isinstance(r.get('create_at'), datetime):
                r['create_at'] = r['create_at'].isoformat()

        return jsonify(records), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch breath records: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/breath_record/feeling', methods=['POST'])
def update_breath_feeling():
    data = request.get_json()
    record_id = data.get('id')
    feeling = data.get('feeling')

    if not record_id or not feeling:
        return jsonify({'error': 'Missing id or feeling'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor()
        query = "UPDATE breath_record SET feeling = %s WHERE id = %s"
        cursor.execute(query, (feeling, record_id))
        connection.commit()
        return jsonify({'message': 'Feeling updated successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to update feeling: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

# 聊天機器人模組
db = mysql.connector.connect(
    host='127.0.0.1',
    user='root',
    password='',
    database='sd',
    charset='utf8mb4'
)
cursor = db.cursor()

OLLAMA_API_URL = 'http://localhost:11434/api/chat'  # Ollama LLM API 端點

# ============ 依 session 取得/判斷 user_id =============
def get_user_id():
    user_id = session.get('user_id')
    if not user_id:
        if request.method == 'POST':
            try:
                user_id = (request.json or {}).get('user_id')
            except Exception:
                user_id = None
        else:
            user_id = request.args.get('user_id')
    return int(user_id) if user_id else 0

# ============ 取得/設定目前聊天室名稱 ============
def get_current_name():
    uid = get_user_id()
    key = f'current_conv_{uid}'
    return session.get(key, 'default')

def set_current_name(conv_name):
    uid = get_user_id()
    session[f'current_conv_{uid}'] = conv_name

# ============ 取得/儲存當前聊天室訊息 ============
def get_messages():
    uid = get_user_id()
    key = f'messages_{uid}_{get_current_name()}'
    return session.setdefault(key, [])

def save_messages(messages):
    uid = get_user_id()
    key = f'messages_{uid}_{get_current_name()}'
    session[key] = messages

# ============ 儲存單一訊息到資料庫 ============
def save_message_to_db(user_id, conversation, role, content):
    sql = "INSERT INTO robot_chat_history (user_id, conversation, role, content) VALUES (%s, %s, %s, %s)"
    val = (user_id, conversation, role, content)
    cursor.execute(sql, val)
    db.commit()

# ============ 更新聊天室名稱 (AI自動命名後) ============
def update_conversation_name(user_id, old_name, new_name):
    sql = "UPDATE robot_chat_history SET conversation=%s WHERE user_id=%s AND conversation=%s"
    cursor.execute(sql, (new_name, user_id, old_name))
    db.commit()

# ============ 利用AI產生聊天室標題 ============
def ai_generate_title(first_message):
    payload = {
        "model": "gemma3:12b",
        "messages": [
            {
                "role": "system",
                "content":  "你是一個對話標題產生器。"
                            "請你根據下方訊息內容，**只回一個 8~16 字內的明確主題作為標題**，不要多加解釋、不要加入任何標點符號，也不要問問題。"
                            "直接列出主題即可，例如：『工作壓力抒發』、『與朋友聚餐心得』、『心情低落的週末』。"
            },
            {
                "role": "user",
                "content": first_message
            }
        ],
        "stream": False
    }
    try:
        res = requests.post(OLLAMA_API_URL, json=payload, timeout=60)
        data = res.json()
        title = data.get("message", {}).get("content", "").strip().replace('\n', '')
        return title[:16] if title else "未命名聊天室"
    except Exception:
        return "未命名聊天室"



# ============ 切換聊天室 ============
@app.route('/switch', methods=['POST'])
def switch_conversation():
    user_id = get_user_id()
    name = request.json.get('conversation', '').strip() or 'default'
    # 標記該聊天室是否已 AI 命名
    session[f'ai_titled_{user_id}'] = not name.startswith('untitled_')
    set_current_name(name)
    # 初始化 session 中的訊息快取
    key = f'messages_{user_id}_{name}'
    if key not in session:
        session[key] = []
    return jsonify({'status': 'switched', 'conversation': name})

# ============ 重設目前聊天室內容 ============
@app.route('/reset', methods=['POST'])
def reset_conversation():
    user_id = get_user_id()
    key = f'messages_{user_id}_{get_current_name()}'
    session[key] = []
    return jsonify({'status': 'cleared', 'conversation': get_current_name()})

# ============ 取得該用戶所有聊天室清單 ============
@app.route('/conversations', methods=['GET'])
def list_conversations():
    user_id = get_user_id()
    sql = "SELECT DISTINCT conversation FROM robot_chat_history WHERE user_id=%s"
    cursor.execute(sql, (user_id,))
    conversations = [row[0] for row in cursor.fetchall()]
    current = session.get(f'current_conv_{user_id}', 'default')
    if current not in conversations:
        conversations.append(current)
    return jsonify({
        'conversations': conversations,
        'current': current
    })

# ============ 取得目前聊天室歷史訊息 ============
@app.route('/history', methods=['GET'])
def get_history():
    user_id = get_user_id()
    conversation = get_current_name()
    sql = "SELECT role, content FROM robot_chat_history WHERE user_id=%s AND conversation=%s ORDER BY id"
    cursor.execute(sql, (user_id, conversation))
    rows = cursor.fetchall()
    history = [
        {'role': role, 'content': content}
        for (role, content) in rows
        if content and content.strip()
    ]
    return jsonify({'history': history})

# ============ 發送訊息/串流回覆 ============
@app.route('/chat', methods=['POST'])
def chat():
    user_id = get_user_id()
    user_message = request.json.get('message', '').strip()
    conversation = get_current_name()
    is_new_conv = conversation.startswith("untitled_")
    ai_titled = session.get(f'ai_titled_{user_id}', False)

    if not user_message:
        return Response('', content_type='text/plain')

    messages = get_messages()
    # 若為新聊天室，加上預設 system prompt
    if not messages:
        messages.append({
            'role': 'system',
            'content': (
                '你是一位親切、有耐心的朋友，請用繁體中文和我聊天。'
                '不用太正式，像平常朋友聊天一樣就好，溫暖、有共鳴，讓我覺得被理解就好。'
            )
        })

    messages.append({'role': 'user', 'content': user_message})
    save_message_to_db(user_id, conversation, 'user', user_message)

    # 若是新聊天室且未 AI 命名，呼叫 AI 產生新標題並切換
    if is_new_conv and not ai_titled:
        title = ai_generate_title(user_message)
        update_conversation_name(user_id, conversation, title)
        set_current_name(title)
        session[f'ai_titled_{user_id}'] = True
        # 轉移 session 快取
        session[f'messages_{user_id}_{title}'] = session.pop(f'messages_{user_id}_{conversation}')
        conversation = title

    # 只取最後 6 則用戶訊息 + system prompt 給 LLM
    trimmed = [m for m in messages if m['role'] != 'system']
    session_msgs = messages[:1] + trimmed[-6:]
    save_messages(messages)

    payload = {
        'model': 'gemma3:12b',
        'messages': session_msgs,
        'stream': True
    }

    full_response = {'value': ''}

    @stream_with_context
    def generate():
        try:
            with requests.post(OLLAMA_API_URL, json=payload, stream=True, timeout=180) as r:
                for line in r.iter_lines():
                    if not line:
                        continue
                    try:
                        data = json.loads(line.decode('utf-8'))
                        chunk = data.get('message', {}).get('content', '')
                    except json.JSONDecodeError:
                        chunk = '[解析錯誤]'
                    full_response['value'] += chunk
                    yield chunk
        except Exception as e:
            yield f'[連線錯誤：{e}]'

        # 傳完訊息再將 assistant 回覆寫入 session 及資料庫
        if full_response['value'].strip():
            msgs = get_messages()
            msgs.append({'role': 'assistant', 'content': full_response['value']})
            save_messages(msgs)
            save_message_to_db(user_id, conversation, 'assistant', full_response['value'])

    return Response(generate(), content_type='text/plain')

# ============ 產生並儲存摘要 ============
@app.route('/finalize', methods=['POST'])
def finalize_conversation():
    user_id = get_user_id()
    messages = get_messages()
    if not messages:
        return jsonify({'status': 'no_messages'})
    summary = generate_summary(messages)
    save_summary_to_db(user_id, summary)
    return jsonify({'status': 'summary_saved', 'summary': summary})

# ============ 呼叫 AI 產生摘要 ============
def generate_summary(messages):
    full_content = ''
    for m in messages:
        role = "你" if m["role"] == "user" else "AI"
        full_content += f"{role}：{m['content']}\n"
    summary_prompt = [
        {
            "role": "system",
            "content": (
                "請你扮演摘要助手，針對以下對話內容，用一句話摘要這段對話的情緒或主旨。"
                "不要安慰、不要延續回應，直接給出明確、簡潔的總結即可。"
            )
        },
        {
            "role": "user",
            "content": full_content.strip()
        }
    ]
    payload = {
        "model": "gemma3:12b",
        "messages": summary_prompt,
        "stream": False
    }
    try:
        res = requests.post(OLLAMA_API_URL, json=payload, timeout=60)
        data = res.json()
        return data.get("message", {}).get("content", "").strip()
    except Exception as e:
        return f"[摘要失敗：{e}]"

# ============ 儲存摘要到資料庫 ============
def save_summary_to_db(user_id, summary):
    sql = "INSERT INTO robot_chat (user_id, summary, keywords, emotion_tag) VALUES (%s, %s, %s, %s)"
    val = (user_id, summary, '', '')
    cursor.execute(sql, val)
    db.commit()

# --- 用 OLLAMA 取得文字向量 ---
def embed_text(text):
    resp = requests.post(
        OLLAMA_EMBED_URL,
        json={'model': EMBED_MODEL, 'input': text}
    )
    data = resp.json()
    if 'error' in data:
        raise RuntimeError(f"Ollama 回傳錯誤: {data['error']}")
    vecs = data.get('embeddings') or data.get('embedding')
    if vecs is None:
        raise RuntimeError(f"Embed API 回傳格式異常: {data}")
    return vecs[0] if isinstance(vecs[0], list) else vecs

# --- 用 LLM 產生摘要與主題 ---
def analyze_content_with_ai(diary):
    messages = [
        {
            "role": "system",
            "content": (
                "你是一個只能輸出 JSON 的 AI 模型，請閱讀使用者的日記內容，"
                "生成一段具有情緒、原因與內心反應的摘要，長度約 100-150 字。\n"
                "並回傳以下 JSON 格式：\n"
                "{\n"
                "  \"summary\": \"（摘要文字）\",\n"
                "  \"themes\": [\n"
                "    \"請具體描述主題，例如：\",\n"
                "    \"因為失眠導致情緒不穩\",\n"
                "    \"與母親互動感到溫暖\",\n"
                "    \"對未來不確定性感到焦慮\"\n"
                "  ]\n"
                "}\n"
                "⚠️ 只能輸出 JSON，不能包含說明、標題或開場白。"
            )
        },
        {
            "role": "user",
            "content": diary
        }
    ]

    payload = {
        'model': 'gemma3:12b',
        'messages': messages,
        'stream': False,
        'options': {
            'num_gpu': 1,
            'low_vram': False,
            'main_gpu': 0,
            'num_ctx': 8192,
            'num_thread': 12,
            'keep_alive': -1
        }
    }

    try:
        # 請求 LLM 產生摘要
        resp = requests.post(OLLAMA_CHAT_URL, json=payload, timeout=300)
        resp.raise_for_status()
        content = resp.json().get("message", {}).get("content", "").strip()
        match = re.search(r'{.*}', content, re.DOTALL)
        if not match:
            raise json.JSONDecodeError("找不到 JSON 區段", content, 0)
        clean_json = match.group(0)
        parsed = json.loads(clean_json)
        return {
            "summary": parsed.get("summary", ""),
            "themes": parsed.get("themes", [])
        }
    except Exception as e:
        return {
            "summary": "",
            "themes": [],
            "error": str(e)
        }

# --- API: 今日情緒摘要與主題 ---
@app.route('/analyze_today_all', methods=['GET'])
def analyze_today_all():
    today_str = datetime.now().strftime('%Y-%m-%d')
    user_id = request.args.get('user_id')

    # 查詢 today 當天所有 now 紀錄
    sql_now = """
    SELECT id, note, joy, sadness, anger, positive, anxiety, exhaust
    FROM now
    WHERE DATE(create_at) = %s AND user_id = %s
    """
    cursor.execute(sql_now, (today_str, user_id))
    now_records = cursor.fetchall()

    # 查詢 diaries 當天日記
    sql_diary = """
    SELECT id, content, joy, sadness, anger, positive, anxiety, exhaust
    FROM diaries
    WHERE DATE(create_at) = %s AND user_id = %s
    LIMIT 1
    """
    cursor.execute(sql_diary, (today_str, user_id))
    diary = cursor.fetchone()

    # 沒有資料則回傳錯誤
    if not now_records and not diary:
        return jsonify({'error': '今天沒有任何資料'}), 404

    # 組合 all_text 當作 prompt 給 LLM 分析
    all_text = ""
    if diary:
        all_text += (
            f"【今日日記】\n"
            f"內容：{diary['content']}\n"
            f"情緒指標："
            f"喜悅（joy）：{diary['joy']}，"
            f"悲傷（sadness）：{diary['sadness']}，"
            f"憤怒（anger）：{diary['anger']}，"
            f"正向（positive）：{diary['positive']}，"
            f"焦慮（anxiety）：{diary['anxiety']}，"
            f"疲憊（exhaust）：{diary['exhaust']}\n\n"
        )
    if now_records:
        for idx, rec in enumerate(now_records, start=1):
            all_text += (
                f"【即時紀錄{idx}】\n"
                f"內容：{rec['note']}\n"
                f"情緒指標："
                f"喜悅（joy）：{rec['joy']}，"
                f"悲傷（sadness）：{rec['sadness']}，"
                f"憤怒（anger）：{rec['anger']}，"
                f"正向（positive）：{rec['positive']}，"
                f"焦慮（anxiety）：{rec['anxiety']}，"
                f"疲憊（exhaust）：{rec['exhaust']}\n\n"
            )

    # 加上 LLM prompt
    all_text += "請根據今天所有日記與即時紀錄內容、情緒數值，產生一段全日總結（100-150字），並列出具體主題（例如：人際關係、壓力來源、學業等）。"

    # 送到 LLM 取得摘要結果
    ai_result = analyze_content_with_ai(all_text)

    # 回傳 JSON 給前端
    return jsonify({
        "summary": ai_result.get("summary", ""),
        "themes": ai_result.get("themes", []),
        "now_count": len(now_records),
        "has_diary": bool(diary)
    })

# --- API: 精油推薦（用摘要或日記都可）---
@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json(silent=True) or {}
    diary = data.get('diary', '').strip()
    if not diary:
        return jsonify({'error': '請輸入日記內容'}), 400

    # 1. 產生日記向量，查詢語意最接近的精油（取前三個）
    try:
        qvec = embed_text(diary)
        results = col.query(query_embeddings=[qvec], n_results=3)
        oil_docs = results['documents'][0]
        oil_ids = results['ids'][0]
        if not oil_docs:
            return jsonify({"error": "查無相關精油，請確認資料庫有資料"}), 404
    except Exception as e:
        return jsonify({'error': f'精油向量查詢失敗：{e}'}), 500

    # 2. 建立給 LLM 的精油候選清單
    candidates = '\n'.join([f"{idx+1}. {oil_docs[idx]}" for idx in range(len(oil_docs))])

    # 3. 用 LLM 選最適合精油與理由
    messages = [
        {
            "role": "system",
            "content": (
                "你是一位芳療專家，根據下方日記內容和精油候選名單，"
                "只能從候選名單選出最適合的一款精油，並嚴格按照如下 JSON 格式回覆："
                "{\"oil\":\"精油名稱\",\"reason\":\"推薦理由（必須超過20字且不可留空）\"}。"
                "不能創造名單外的精油，不能省略任何欄位，不能只給名稱，不可回覆其他說明或格式。\n"
                f"候選精油：\n{candidates}"
            )
        },
        {
            "role": "user",
            "content": f"日記內容：\n{diary}"
        }
    ]

    payload = {
        'model': 'gemma3:12b',
        'messages': messages,
        'stream': False,
        'options': {
            'num_gpu': 1,
            'main_gpu': 0,
            'low_vram': False,
            'num_ctx': 8192,
            'keep_alive': -1
        }
    }

    try:
        # 請求 LLM 給予精油推薦
        resp = requests.post(OLLAMA_CHAT_URL, json=payload, timeout=180)
        resp.raise_for_status()
        content = resp.json().get("message", {}).get("content", "").strip()
        match = re.search(r'\{.*?\}', content, re.DOTALL)
        parsed = json.loads(match.group(0)) if match else {}
        oil_name = parsed.get("oil", "")
        reason = parsed.get("reason", "")
        print("AI raw output:", content)

    except Exception as e:
        return jsonify({'error': f'AI推薦失敗/格式錯誤：{e}', 'raw': content if 'content' in locals() else ''}), 500

    # 4. 回傳推薦精油與描述
    oil_desc = ""
    for doc in oil_docs:
        if oil_name and doc.startswith(oil_name):
            oil_desc = doc
            break
    if not oil_desc:
        oil_desc = "查無精油功效（模型可能回傳了名單外的精油，請再試一次）。"
    if not reason:
        reason = "AI未正確給出推薦理由，請重新嘗試。"

    return jsonify({
        "oil": oil_name,
        "oil_desc": oil_desc,
        "reason": reason,
        "candidates": oil_docs,
        "diary": diary
    })


@app.route('/recommend_today_oil', methods=['GET'])
def recommend_today_oil():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "請帶上 user_id"}), 400

    print("Step 1: Start get summary...")
    try:
        # 1. 先取得當天情緒摘要
        summary_resp = requests.get(
            "http://127.0.0.1:5000/analyze_today_all",
            params={'user_id': user_id},
            timeout=120
        )
        summary_json = summary_resp.json()
        summary_text = summary_json.get('summary', '')
        print("Step 1: Got summary:", summary_text)
        if not summary_text:
            return jsonify({"error": "找不到今日摘要", "raw": summary_json}), 400
    except Exception as e:
        print("Step 1 failed:", e)
        return jsonify({"error": f"今日摘要API失敗: {e}"}), 500

    print("Step 2: Start analyze...")
    try:
        # 2. 再用摘要去推薦精油
        analyze_resp = requests.post(
            "http://127.0.0.1:5000/analyze",
            json={'diary': summary_text},
            timeout=120
        )
        analyze_json = analyze_resp.json()
        print("Step 2: Got analyze:", analyze_json)
    except Exception as e:
        print("Step 2 failed:", e)
        return jsonify({"error": f"推薦精油API失敗: {e}"}), 500

    # 只取精油名稱
    oil_name = analyze_json.get('oil', '').strip()
    if not oil_name:
        return jsonify({"error": "AI 沒有推薦精油名稱", "raw": analyze_json}), 400

    print("Step 3: 查詢油品 id...")
    try:
        # 3. 查詢精油 id
        sql = "SELECT id FROM oil WHERE name = %s"
        cursor.execute(sql, (oil_name,))
        row = cursor.fetchone()
        if not row:
            return jsonify({"error": f"資料庫查無精油名稱: {oil_name}"}), 400
        oil_id = row['id']
    except Exception as e:
        print("Step 3 failed:", e)
        return jsonify({"error": f"查詢油品失敗: {e}"}), 500

    print(f"Step 4: 更新使用者 {user_id} 的 oil_id -> {oil_id}")
    try:
        # 4. 更新 user 的 oil_id
        sql_update = "UPDATE users SET oil_id = %s WHERE id = %s"
        cursor.execute(sql_update, (oil_id, user_id))
        db.commit()
    except Exception as e:
        print("Step 4 failed:", e)
        return jsonify({"error": f"更新使用者 oil_id 失敗: {e}"}), 500

    return jsonify({
        "oil": oil_name,
        "oil_id": oil_id,
        "status": "success"
    })

# ============ 啟動 Flask 伺服器 ============
if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True, threaded=True)
