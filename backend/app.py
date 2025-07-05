from flask import Flask, request, jsonify, render_template, session, Response, stream_with_context
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime
from flask_session import Session
import requests



app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
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
            print(f"[路由] 找到了 user_id：{result['user_id']}")
            return jsonify(result), 200
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
    user_id = data.get('user_id')
    date = data.get('date')
    type = data.get('type')
    emotions = data.get('emotions')
    mixed_color = data.get('mixed_color')  # 統一為 mixed_color
    mood_text = data.get('mood_text')      # 統一為 mood_text
    details = data.get('details')
    is_english = data.get('is_english', False)  # 統一為 is_english

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
    user_id = request.args.get('user_id')
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
        # 查詢 diaries
        query_diaries = """
        SELECT id, user_id, content AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
               color_mix AS mixed_color, create_at, is_english, details
        FROM diaries WHERE user_id = %s AND DATE(create_at) = %s
        """
        cursor.execute(query_diaries, (user_id, entry_date))
        day_entries = cursor.fetchall()

        # 查詢 now
        query_now = """
        SELECT id, user_id, note AS mood_text, joy, sadness, anger, positive, anxiety, exhaust, 
               NULL AS mixed_color, create_at, is_english, details
        FROM now WHERE user_id = %s AND DATE(create_at) = %s
        """
        cursor.execute(query_now, (user_id, entry_date))
        moment_entries = cursor.fetchall()

        # 合併並格式化
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
    user_id = request.args.get('user_id')
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
    user_id = data.get('user_id')
    duration = data.get('duration')
    min_value = data.get('min')
    felling = data.get('felling')
    type_value = data.get('type', '引導')

    if not user_id or min_value is None:
        return jsonify({'error': 'Missing required fields: user_id or min'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor()
        query = """
            INSERT INTO breath_record (user_id, duration, min, felling, type)
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (user_id, duration, min_value, felling, type_value))
        connection.commit()
        return jsonify({'message': 'Breath record saved successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to save breath record: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/breath_record/<date>', methods=['GET'])
def get_breath_records_by_date(date):
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400

    try:
        entry_date = datetime.strptime(date, '%Y-%m-%d').date().isoformat()
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = "SELECT * FROM breath_record WHERE user_id = %s AND DATE(create_at) = %s"
        cursor.execute(query, (user_id, entry_date))
        records = cursor.fetchall()
        return jsonify(records), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch breath records: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

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
        return jsonify(records), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch breath records: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/breath_record/felling', methods=['POST'])
def update_breath_felling():
    data = request.get_json()
    record_id = data.get('id')
    felling = data.get('felling')

    if not record_id or not felling:
        return jsonify({'error': 'Missing id or felling'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor()
        query = "UPDATE breath_record SET felling = %s WHERE id = %s"
        cursor.execute(query, (felling, record_id))
        connection.commit()
        return jsonify({'message': 'Felling updated successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to update felling: {e}'}), 500
    finally:
        cursor.close()
        connection.close()
# 聊天機器人模組
OLLAMA_API_URL = 'http://localhost:11434/api/chat'

# === User/Session 工具 ===
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

def get_current_name():
    uid = get_user_id()
    key = f'current_conv_{uid}'
    return session.get(key, 'default')

def set_current_name(conv_name):
    uid = get_user_id()
    session[f'current_conv_{uid}'] = conv_name

def get_messages():
    uid = get_user_id()
    key = f'messages_{uid}_{get_current_name()}'
    return session.setdefault(key, [])

def save_messages(messages):
    uid = get_user_id()
    key = f'messages_{uid}_{get_current_name()}'
    session[key] = messages

def save_message_to_db(user_id, conversation, role, content):
    connection = get_db_connection()
    if not connection:
        return
    try:
        cursor = connection.cursor()
        sql = "INSERT INTO robot_chat_history (user_id, conversation, role, content) VALUES (%s, %s, %s, %s)"
        cursor.execute(sql, (user_id, conversation, role, content))
        connection.commit()
    except Exception as e:
        print(f"[DB] 儲存對話失敗: {e}")
    finally:
        cursor.close()
        connection.close()

def update_conversation_name(user_id, old_name, new_name):
    connection = get_db_connection()
    if not connection:
        return
    try:
        cursor = connection.cursor()
        sql = "UPDATE robot_chat_history SET conversation=%s WHERE user_id=%s AND conversation=%s"
        cursor.execute(sql, (new_name, user_id, old_name))
        connection.commit()
    except Exception as e:
        print(f"[DB] 更新對話名稱失敗: {e}")
    finally:
        cursor.close()
        connection.close()

def ai_generate_title(first_message):
    payload = {
        "model": "gemma3:12b",#改模型測試ollama list查看模型
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

@app.route('/switch', methods=['POST'])
def switch_conversation():
    user_id = get_user_id()
    name = request.json.get('conversation', '').strip() or 'default'
    session[f'ai_titled_{user_id}'] = not name.startswith('untitled_')
    set_current_name(name)
    key = f'messages_{user_id}_{name}'
    if key not in session:
        session[key] = []
    return jsonify({'status': 'switched', 'conversation': name})

@app.route('/reset', methods=['POST'])
def reset_conversation():
    user_id = get_user_id()
    key = f'messages_{user_id}_{get_current_name()}'
    session[key] = []
    return jsonify({'status': 'cleared', 'conversation': get_current_name()})

@app.route('/conversations', methods=['GET'])
def list_conversations():
    user_id = get_user_id()
    connection = get_db_connection()
    if not connection:
        return jsonify({'conversations': [], 'current': ''})
    try:
        cursor = connection.cursor()
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
    finally:
        cursor.close()
        connection.close()

@app.route('/history', methods=['GET'])
def get_history():
    user_id = get_user_id()
    conversation = get_current_name()
    connection = get_db_connection()
    if not connection:
        return jsonify({'history': []})
    try:
        cursor = connection.cursor()
        sql = "SELECT role, content FROM robot_chat_history WHERE user_id=%s AND conversation=%s ORDER BY id"
        cursor.execute(sql, (user_id, conversation))
        rows = cursor.fetchall()
        history = [
            {'role': role, 'content': content}
            for (role, content) in rows
            if content and content.strip()
        ]
        return jsonify({'history': history})
    finally:
        cursor.close()
        connection.close()

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

    if is_new_conv and not ai_titled:
        title = ai_generate_title(user_message)
        update_conversation_name(user_id, conversation, title)
        set_current_name(title)
        session[f'ai_titled_{user_id}'] = True
        session[f'messages_{user_id}_{title}'] = session.pop(f'messages_{user_id}_{conversation}')
        conversation = title

    trimmed = [m for m in messages if m['role'] != 'system']
    session_msgs = messages[:1] + trimmed[-6:]
    save_messages(messages)

    payload = {
        'model': 'gemma3:12b',#改模型測試ollama list查看模型
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

        if full_response['value'].strip():
            msgs = get_messages()
            msgs.append({'role': 'assistant', 'content': full_response['value']})
            save_messages(msgs)
            save_message_to_db(user_id, conversation, 'assistant', full_response['value'])

    return Response(generate(), content_type='text/plain')

@app.route('/finalize', methods=['POST'])
def finalize_conversation():
    user_id = get_user_id()
    messages = get_messages()
    if not messages:
        return jsonify({'status': 'no_messages'})
    summary = generate_summary(messages)
    save_summary_to_db(user_id, summary)
    return jsonify({'status': 'summary_saved', 'summary': summary})

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
        "model": "gemma3:12b",#改模型測試ollama list查看模型
        "messages": summary_prompt,
        "stream": False
    }
    try:
        res = requests.post(OLLAMA_API_URL, json=payload, timeout=60)
        data = res.json()
        return data.get("message", {}).get("content", "").strip()
    except Exception as e:
        return f"[摘要失敗：{e}]"

def save_summary_to_db(user_id, summary):
    connection = get_db_connection()
    if not connection:
        return
    try:
        cursor = connection.cursor()
        sql = "INSERT INTO robot_chat (user_id, summary, keywords, emotion_tag) VALUES (%s, %s, %s, %s)"
        val = (user_id, summary, '', '')
        cursor.execute(sql, val)
        connection.commit()
    finally:
        cursor.close()
        connection.close()
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)


