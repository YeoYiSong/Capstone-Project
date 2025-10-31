from flask import Flask, request, jsonify, render_template, session, Response, stream_with_context
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime, timedelta,date
import time
from flask_session import Session
import requests
import contextlib
import chromadb
import re
import uuid
from itertools import chain
from typing import Callable, Type, Tuple


app = Flask(__name__)
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
client = chromadb.PersistentClient(path=r"C:\demosmaily\backend\chroma_db")  # 需更改位置
col = client.get_or_create_collection(name="essential_oils")

# --- LLM API 參數 ---
OLLAMA_CHAT_URL = 'http://localhost:11434/api/chat'
OLLAMA_EMBED_URL = 'http://localhost:11434/api/embed'
EMBED_MODEL = 'nn200433/text2vec-bge-large-chinese'
def retry(fn: Callable, retries: int = 3, backoffs: Tuple[float, ...]=(0.5, 1, 2),
          exceptions: Tuple[Type[Exception], ...]=(Exception,), on_err=None):
    last_e = None
    for i in range(retries):
        try:
            return fn()
        except exceptions as e:
            last_e = e
            if on_err:
                try: on_err(e, i+1)
                except: pass
            if i < retries - 1:
                time.sleep(backoffs[min(i, len(backoffs)-1)])
    raise last_e
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
    user_id = session.get('user_id')or data.get('user_id')
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

def _parse_date(s: str) -> date:
    return datetime.strptime(s, "%Y-%m-%d").date()

@app.get("/diary/exists")
def diary_exists():
    # 允許從 query 讀 user_id（前端會帶），否則落回 session
    uid = request.args.get("user_id") or session.get("user_id")
    if not uid:
        return jsonify({"error": "UNAUTHENTICATED"}), 401

    iso = (request.args.get("date") or "").strip()   # 期待 'YYYY-MM-DD'
    if not iso:
        return jsonify({"error": "MISSING_DATE"}), 400

    try:
        _parse_date(iso)  # 驗證格式
    except ValueError:
        return jsonify({"error": "BAD_DATE_FORMAT", "hint": "YYYY-MM-DD"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # ✅ diaries 沒有 type，僅比對日期與 user_id
        cur.execute(
            """
            SELECT 1
            FROM diaries
            WHERE user_id=%s AND LEFT(create_at, 10)=%s
            LIMIT 1
            """,
            (uid, iso),
        )
        row = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify({"exists": bool(row)}), 200
    except Exception as e:
        return jsonify({"error": "SERVER_ERROR", "message": str(e)}), 500

@app.route('/get_diary_entries/<date>', methods=['GET'])
def get_diary_entries(date):
    user_id = session.get('user_id') or request.args.get('user_id')
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
    user_id = session.get('user_id') or request.args.get('user_id')
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
    user_id = session.get('user_id')or data.get('user_id')
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
    user_id = session.get('user_id') or request.args.get('user_id')
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
    try:
        return (request.json or {}).get('conversation', 'default')
    except Exception:
        return 'default'


# ============ 取得/儲存當前聊天室訊息 ============
def get_messages(user_id, conversation, limit=6):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT role, content
        FROM robot_chat_history
        WHERE user_id = %s AND conversation = %s
        ORDER BY create_at DESC
        LIMIT %s
    """, (user_id, conversation, limit))
    messages = cursor.fetchall()
    cursor.close()
    conn.close()
    return list(reversed(messages))

# ============ 儲存單一訊息到資料庫 ============
def save_message_to_db(user_id, conversation, role, content, create_at=None):
    create_at = create_at or datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    conn = get_db_connection()
    if conn is None:
        return
    try:
        cursor = conn.cursor()
        sql = "INSERT INTO robot_chat_history (user_id, conversation, role, content, create_at) VALUES (%s, %s, %s, %s, %s)"
        val = (user_id, conversation, role, content, create_at)
        cursor.execute(sql, val)
        conn.commit()
    finally:
        cursor.close()
        conn.close()
        
@app.route('/update_conversation', methods=['POST'])
def rename_conversation_api():
    data = request.json
    user_id = get_user_id()
    old_name = data.get('old_name')
    new_name = data.get('new_name')

    if not all([user_id, old_name, new_name]):
        return jsonify({'error': '缺少必要參數'}), 400

    update_conversation_name(user_id, old_name, new_name)
    return jsonify({'status': 'ok', 'message': '聊天室名稱已更新'})

# ============ 更新聊天室名稱 (AI自動命名後) ============
def update_conversation_name(user_id, old_name, new_name):
    conn = get_db_connection()
    if conn is None:
        return
    try:
        cursor = conn.cursor()
        sql = "UPDATE robot_chat_history SET conversation=%s WHERE user_id=%s AND conversation=%s"
        cursor.execute(sql, (new_name, user_id, old_name))
        conn.commit()
    finally:
        cursor.close()
        conn.close()

# ============ 利用AI產生聊天室標題 ============
def ai_generate_title(first_message):
    payload = {
        "model": "gemma3:12b",
        "messages": [
            {
                "role": "system",
                "content":  "你是一個對話標題產生器。"
                            "請你根據下方訊息內容，**只回一個 8~16 字內的明確主題作為標題**，不要多加解釋、不要加入任何標點符號，也不要問問題。"
                            "直接列出主題即可，例如：工作壓力抒發、與朋友聚餐心得、心情低落的週末。"
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
    name = request.json.get('conversation', '').strip() or f"untitled_{datetime.now().strftime('%H%M%S')}"
    return jsonify({'status': 'switched', 'conversation': name})

# ============ 重設目前聊天室內容 ============
@app.route('/reset', methods=['POST'])
def reset_conversation():
    user_id = request.json.get('user_id')
    conversation = request.json.get('conversation')
    if not user_id or not conversation:
        return jsonify({'error': 'Missing parameters'}), 400

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        query = "DELETE FROM robot_chat_history WHERE user_id = %s AND conversation = %s"
        cursor.execute(query, (user_id, conversation))
        conn.commit()
        return jsonify({'status': 'cleared', 'conversation': conversation})
    except Error as e:
        return jsonify({'error': f'Database error: {e}'}), 500
    finally:
        cursor.close()
        conn.close()


# ============ 刪除聊天室 ============
@app.route('/delete', methods=['POST'])
def delete_conversation():
    user_id = get_user_id()
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400
    conversation = request.json.get('conversation')
    if not conversation or conversation == 'untitled_':
        return jsonify({'error': 'Cannot delete untitled_ conversation'}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor()
        query = "DELETE FROM robot_chat_history WHERE user_id = %s AND conversation = %s"
        cursor.execute(query, (user_id, conversation))
        conn.commit()
        return jsonify({'status': 'deleted'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to delete conversation: {e}'}), 500
    finally:
        cursor.close()
        conn.close()


# ============ 取得該用戶所有聊天室清單 ============
@app.route('/conversations', methods=['GET'])
def list_conversations():
    user_id = get_user_id()
    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor()
        sql = "SELECT DISTINCT conversation FROM robot_chat_history WHERE user_id=%s"
        cursor.execute(sql, (user_id,))
        conversations = [row[0] for row in cursor.fetchall()]
        current = session.get(f'current_conv_{user_id}', 'untitled_')
        if current not in conversations:
            conversations.append(current)
        return jsonify({
            'conversations': conversations,
            'current': current
        })
    finally:
        cursor.close()
        conn.close()


# ============ 取得目前聊天室歷史訊息 ============
@app.route('/history', methods=['GET'])
def get_history():
    user_id = get_user_id()
    conversation = request.args.get('conversation')

    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor()
        sql = "SELECT role, content, create_at FROM robot_chat_history WHERE user_id=%s AND conversation=%s ORDER BY id"
        cursor.execute(sql, (user_id, conversation))
        rows = cursor.fetchall()
        history = [
            {'role': role, 'content': content, 'create_at': create_at.strftime('%Y-%m-%d %H:%M:%S')}
            for (role, content, create_at) in rows
            if content and content.strip()
        ]
        return jsonify({'history': history})
    finally:
        cursor.close()
        conn.close()


# ============ 發送訊息/串流回覆 ============
@app.route('/chat', methods=['POST'], endpoint='chat_zh')
def chat():
    user_id = request.json.get('user_id')
    user_message = request.json.get('message', '').strip()
    original_conversation = request.json.get('conversation')  # 接收前端送來的名稱

    # 如果沒有傳 conversation，就給個未命名的
    if not original_conversation:
        original_conversation = 'untitled_' + str(uuid.uuid4())[:8]

    # --- Step 1: 從 session 中查詢 conversation 是否已經被改名過 ---
    conversation = session.get(f'conv_name_map_{user_id}_{original_conversation}', original_conversation)

    # --- Step 2: 檢查是否為第一次 AI 回應 ---
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(*) FROM robot_chat_history WHERE user_id = %s AND conversation = %s AND role = 'assistant'",
        (user_id, conversation)
    )
    has_ai_response = cursor.fetchone()[0] > 0
    cursor.close()
    conn.close()

    should_rename = conversation.startswith("untitled_") and not has_ai_response
    send_conv_name = None

    if should_rename:
        new_name = ai_generate_title(user_message)
        update_conversation_name(user_id, conversation, new_name)

        # 將原名與新名對應記起來（之後前端再送來 untitled_xxx 時能自動轉成新名）
        session[f'conv_name_map_{user_id}_{conversation}'] = new_name

        send_conv_name = new_name
        conversation = new_name  # ⚠️ 更新為新名儲存訊息

    # --- 儲存使用者訊息 ---
    save_message_to_db(user_id, conversation, 'user', user_message)

    # --- 撈取歷史訊息 ---
    history = get_messages(user_id, conversation)
    messages = [{'role': 'system', 'content': '你是一位親切、有耐心的朋友，請用繁體中文和我聊天。'
                '不用太正式，像平常朋友聊天一樣就好，溫暖、有共鳴，讓我覺得被理解就好。'}] + history + [
                   {'role': 'user', 'content': user_message}]

    payload = {'model': 'gemma3:12b', 'messages': messages, 'stream': True}
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
                    except:
                        chunk = '[解析錯誤]'
                    full_response['value'] += chunk
                    yield chunk
        except Exception as e:
            yield f'[錯誤]: {e}'

        if full_response['value'].strip():
            save_message_to_db(user_id, conversation, 'assistant', full_response['value'])

    if send_conv_name:
        def name_stream():
            yield f"CONVERSATION_NAME:{send_conv_name}\n"
        return Response(stream_with_context(chain(name_stream(), generate())), content_type='text/plain')
    else:
        return Response(generate(), content_type='text/plain')

@app.route('/chatEN', methods=['POST'], endpoint='chat_en')#英文聊天
def chat():
    user_id = request.json.get('user_id')
    user_message = request.json.get('message', '').strip()
    original_conversation = request.json.get('conversation')  

    # 如果沒有傳 conversation，就給個未命名的
    if not original_conversation:
        original_conversation = 'untitled_' + str(uuid.uuid4())[:8]

    # --- Step 1: 從 session 中查詢 conversation 是否已經被改名過 ---
    conversation = session.get(f'conv_name_map_{user_id}_{original_conversation}', original_conversation)

    # --- Step 2: 檢查是否為第一次 AI 回應 ---
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(*) FROM robot_chat_history WHERE user_id = %s AND conversation = %s AND role = 'assistant'",
        (user_id, conversation)
    )
    has_ai_response = cursor.fetchone()[0] > 0
    cursor.close()
    conn.close()

    should_rename = conversation.startswith("untitled_") and not has_ai_response
    send_conv_name = None

    if should_rename:
        new_name = ai_generate_title_en(user_message)
        update_conversation_name(user_id, conversation, new_name)

        # 將原名與新名對應記起來（之後前端再送來 untitled_xxx 時能自動轉成新名）
        session[f'conv_name_map_{user_id}_{conversation}'] = new_name

        send_conv_name = new_name
        conversation = new_name  # ⚠️ 更新為新名儲存訊息

    # --- 儲存使用者訊息 ---
    save_message_to_db(user_id, conversation, 'user', user_message)

    # --- 撈取歷史訊息 ---
    history = get_messages(user_id, conversation)
    messages = [{'role': 'system', 'content': 'You are a kind and patient friend. It doesn’t need to be too formal, just like how friends normally talk—warm, understanding, and making me feel truly understood.'}] + history + [
                   {'role': 'user', 'content': user_message}]

    payload = {'model': 'gemma3:12b', 'messages': messages, 'stream': True}
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
                    except:
                        chunk = '[解析錯誤]'
                    full_response['value'] += chunk
                    yield chunk
        except Exception as e:
            yield f'[錯誤]: {e}'

        if full_response['value'].strip():
            save_message_to_db(user_id, conversation, 'assistant', full_response['value'])

    if send_conv_name:
        def name_stream():
            yield f"CONVERSATION_NAME:{send_conv_name}\n"
        return Response(stream_with_context(chain(name_stream(), generate())), content_type='text/plain')
    else:
        return Response(generate(), content_type='text/plain')
    
def ai_generate_title_en(first_message: str) -> str:
    payload = {
        "model": "gemma3:12b",
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a conversation title generator.\n"
                    "Based on the following message, reply with ONLY a short clear title in **English**.\n"
                    "Rules:\n"
                    "- Must be between 8 and 16 characters.\n"
                    "- Do not add punctuation, numbers, or symbols.\n"
                    "- Do not ask questions or give explanations.\n"
                    "- Just output the plain title text.\n"
                    "Examples: Work Stress Chat, Weekend Reflections, Family Dinner Talk"
                )
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
        title = data.get("message", {}).get("content", "").strip().replace("\n", "")
        return title[:16] if title else "Untitled Chat"
    except Exception:
        return "Untitled Chat"


# ============ 產生並儲存摘要 ============
@app.route('/finalize', methods=['POST'])
def is_summary_exists(user_id, conversation):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(*) FROM robot_chat WHERE user_id = %s AND conversation = %s",
        (user_id, conversation)
    )
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    return count > 0
def load_messages_for_summary(user_id, conversation, limit=10):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT role, content
        FROM robot_chat_history
        WHERE user_id = %s AND conversation = %s
        ORDER BY create_at DESC
        LIMIT %s
    """, (user_id, conversation, limit))
    messages = cursor.fetchall()
    cursor.close()
    conn.close()
    return list(reversed(messages))

def finalize_conversation():
    user_id = request.json.get('user_id')
    conversation = request.json.get('conversation')

    if not user_id or not conversation:
        return jsonify({'status': 'missing_parameters'})

    # ✅ 這一行是新增的，避免重複產生摘要
    if is_summary_exists(user_id, conversation):
        return jsonify({'status': 'already_finalized'})

    messages = load_messages_for_summary(user_id, conversation, limit=10)
    if not messages:
        return jsonify({'status': 'no_messages'})

    result = analyze_content_with_ai(
        '\n'.join([f"{'你' if m['role']=='user' else 'AI'}：{m['content']}" for m in messages])
    )
    save_summary_to_db(user_id, result["summary"], result.get("themes", []), conversation)
    return jsonify({'status': 'summary_saved', 'summary': result["summary"], 'themes': result.get("themes", [])})

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
def save_summary_to_db(user_id, summary, themes=None, conversation=None, emotion=None):
    sql = "INSERT INTO robot_chat (user_id, summary, keywords, emotion_tag, conversation) VALUES (%s, %s, %s, %s, %s)"
    val = (
        user_id,
        summary,
        ', '.join(themes or []),
        emotion or '',
        conversation or ''
    )
    conn = get_db_connection()
    if conn is None:
        return
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, val)
            conn.commit()
    finally:
        conn.close()


# --- 用 OLLAMA 取得文字向量 ---
def embed_text(text):
    def _call():
        resp = requests.post(
            OLLAMA_EMBED_URL,
            json={'model': EMBED_MODEL, 'input': text},
            timeout=60  
        )
        resp.raise_for_status()
        data = resp.json()
        if 'error' in data:
            raise RuntimeError(f"Ollama Embed 錯誤: {data['error']}")
        vecs = data.get('embeddings') or data.get('embedding')
        if vecs is None:
            raise RuntimeError(f"Embed API 回傳格式異常: {data}")
        return vecs[0] if isinstance(vecs[0], list) else vecs

    return retry(_call, retries=3)


# --- 用 LLM 產生摘要與主題 ---
def analyze_content_with_ai(diary):
    messages = [
        {
            "role": "system",
            "content": (
                "優先輸出 JSON：{\"summary\":\"...\",\"themes\":[\"...\",\"...\"]}\n"
                "若無法產出合法 JSON，也請至少先輸出 100-150 字連貫摘要（不含程式碼區塊）。"
            )
        },
        {"role": "user", "content": diary}
    ]
    payload = {
        'model': 'gemma3:12b',
        'messages': messages,
        'stream': False,
        'options': {'num_ctx': 8192, 'keep_alive': -1}
    }

    def _call():
        r = requests.post(OLLAMA_API_URL, json=payload, timeout=120)  # 首呼適度放寬
        r.raise_for_status()
        try:
            data = r.json()
            content = (data.get("message", {}) or {}).get("content", "") or r.text
        except Exception:
            content = r.text
        content = (content or "").strip()

        # 先嘗試擷取淺層 JSON（避免貪婪）
        m = re.search(r'\{[^{}]*\}', content, re.DOTALL)
        if m:
            try:
                parsed = json.loads(m.group(0))
                return {
                    "summary": parsed.get("summary", "") or "",
                    "themes": parsed.get("themes", []) or []
                }
            except Exception:
                pass

        # fallback：把模型輸出當純文字摘要用，避免空 summary 造成 400
        text = re.sub(r'```.*?```', '', content, flags=re.DOTALL)
        text = re.sub(r'\s+', ' ', text).strip()
        text = text[:180]
        return {"summary": text, "themes": []}

    try:
        return retry(_call, retries=3)
    except Exception as e:
        return {"summary": "", "themes": [], "error": str(e)}


# --- API: 今日情緒摘要與主題 ---
@app.route('/analyze_today_all', methods=['GET'])
def analyze_today_all():
    today_str = datetime.now().strftime('%Y-%m-%d')
    user_id = request.args.get('user_id')
    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = conn.cursor(dictionary=True)

        sql_now = """
        SELECT id, note, joy, sadness, anger, positive, anxiety, exhaust
        FROM now
        WHERE DATE(create_at) = %s AND user_id = %s
        """
        cursor.execute(sql_now, (today_str, user_id))
        now_records = cursor.fetchall()

        sql_diary = """
        SELECT id, content, joy, sadness, anger, positive, anxiety, exhaust
        FROM diaries
        WHERE DATE(create_at) = %s AND user_id = %s
        LIMIT 1
        """
        cursor.execute(sql_diary, (today_str, user_id))
        diary = cursor.fetchone()
    finally:
        conn.close()

    if not now_records and not diary:
        return jsonify({'error': '今天沒有任何資料'}), 404

    all_text = ""
    if diary:
        all_text += (
            f"【今日日記】\n"
            f"內容：{diary['content']}\n"
            f"情緒指標：喜悅（joy）：{diary['joy']}，悲傷（sadness）：{diary['sadness']}，"
            f"憤怒（anger）：{diary['anger']}，正向（positive）：{diary['positive']}，"
            f"焦慮（anxiety）：{diary['anxiety']}，疲憊（exhaust）：{diary['exhaust']}\n\n"
        )
    for idx, rec in enumerate(now_records, start=1):
        all_text += (
            f"【即時紀錄{idx}】\n"
            f"內容：{rec['note']}\n"
            f"情緒指標：喜悅（joy）：{rec['joy']}，悲傷（sadness）：{rec['sadness']}，"
            f"憤怒（anger）：{rec['anger']}，正向（positive）：{rec['positive']}，"
            f"焦慮（anxiety）：{rec['anxiety']}，疲憊（exhaust）：{rec['exhaust']}\n\n"
        )

    all_text += "請根據今天所有日記與即時紀錄內容、情緒數值，產生一段全日總結（100-150字），並列出具體主題。"

    ai_result = analyze_content_with_ai(all_text)
    return jsonify({
        "summary": ai_result.get("summary", ""),
        "themes": ai_result.get("themes", []),
        "now_count": len(now_records),
        "has_diary": bool(diary)
    })
def get_today_summary(user_id):
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    tomorrow = today + timedelta(days=1)

    conn = get_db_connection()
    if conn is None:
        return None
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, note, joy, sadness, anger, positive, anxiety, exhaust, create_at
            FROM now
            WHERE user_id=%s AND create_at >= %s AND create_at < %s
            ORDER BY create_at ASC
        """, (user_id, today, tomorrow))
        now_records = cursor.fetchall()

        cursor.execute("""
            SELECT id, content, joy, sadness, anger, positive, anxiety, exhaust, create_at
            FROM diaries
            WHERE user_id=%s AND create_at >= %s AND create_at < %s
            ORDER BY create_at ASC
            LIMIT 1
        """, (user_id, today, tomorrow))
        diary = cursor.fetchone()
    finally:
        conn.close()

    if not now_records and not diary:
        return None

    parts = []
    if diary:
        parts.append(
            f"【今日日記】\n內容：{diary['content']}\n情緒指標：喜悅：{diary['joy']}，悲傷：{diary['sadness']}，"
            f"憤怒：{diary['anger']}，正向：{diary['positive']}，焦慮：{diary['anxiety']}，疲憊：{diary['exhaust']}\n"
        )
    for idx, rec in enumerate(now_records, 1):
        parts.append(
            f"【即時紀錄{idx}】\n內容：{rec['note']}\n情緒指標：喜悅：{rec['joy']}，悲傷：{rec['sadness']}，"
            f"憤怒：{rec['anger']}，正向：{rec['positive']}，焦慮：{rec['anxiety']}，疲憊：{rec['exhaust']}\n"
        )
    parts.append("請根據今天所有日記與即時紀錄內容、情緒數值，產生一段全日總結（100-150字），並列出具體主題。")

    return analyze_content_with_ai("\n".join(parts))
def _warmup():
    try:
        requests.post(OLLAMA_API_URL, json={"model":"gemma3:12b","messages":[{"role":"user","content":"ping"}]}, timeout=5)
    except: pass
    try:
        requests.post(OLLAMA_EMBED_URL, json={"model":EMBED_MODEL,"input":"warmup"}, timeout=5)
    except: pass

_warmup()
# 顯示所有精油清單
# 顯示所有精油清單（改：用資料庫）
@app.route('/get_all_oils', methods=['GET'])
def get_all_oils():
    conn = get_db_connection()
    if conn is None:
        return jsonify({'error': '資料庫連線失敗'}), 500
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("""
            SELECT id, name, price, meaning, effect
            FROM oil
            ORDER BY id
        """)
        rows = cur.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": f"讀取精油資料失敗：{e}"}), 500
    finally:
        conn.close()


# --- API: 精油推薦（用摘要或日記都可）---
@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.get_json(silent=True) or {}
    diary = data.get('diary', '').strip()
    if not diary:
        return jsonify({'error': '請輸入日記內容'}), 400

    try:
        qvec = embed_text(diary)
        results = col.query(query_embeddings=[qvec], n_results=3)
        oil_docs = results['documents'][0]
        oil_ids = results['ids'][0]
        if not oil_docs:
            return jsonify({"error": "查無相關精油，請確認資料庫有資料"}), 404
    except Exception as e:
        return jsonify({'error': f'精油向量查詢失敗：{e}'}), 500

    candidates = '\n'.join([f"{idx+1}. {oil_docs[idx]}" for idx in range(len(oil_docs))])

    messages = [
        {
            "role": "system",
            "content": (
                "你是一位芳療專家，根據下方日記內容和精油候選名單，"
                "只能從候選名單選出最適合的一款精油，並嚴格按照如下 JSON 格式回覆："
                "{\"oil\":\"精油名稱\",\"reason\":\"推薦理由（必 須超過20字且不可留空）\"}。"
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

def purge_outdated_recos(user_id: int | str):
    """刪除這位使用者『不是今天』的所有推薦（自動換日重置）。"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            DELETE FROM user_daily_oil_recos
            WHERE user_id = %s AND reco_date <> CURDATE()
        """, (user_id,))
        conn.commit()
    finally:
        try: conn.close()
        except: pass

def has_today_reco_for_oil(user_id: int | str, oil_id: int | str) -> bool:
    """今天是否已經推薦過這支油。"""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT 1
            FROM user_daily_oil_recos
            WHERE user_id = %s AND reco_date = CURDATE() AND oil_id = %s
            LIMIT 1
        """, (user_id, oil_id))
        return cur.fetchone() is not None
    finally:
        try: conn.close()
        except: pass

def insert_today_reco(user_id: int | str, oil_id: int | str,
                      reason: str | None, oil_desc: str | None,
                      source: str | None):
    """
    寫入今天一筆推薦（若 unique 衝突就略過，以達成『同油不重複』）。
    回傳 1=成功新增；0=已存在（被 INSERT IGNORE）。
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            INSERT IGNORE INTO user_daily_oil_recos
                (user_id, reco_date, oil_id, reason, oil_desc, source, created_at)
            VALUES
                (%s, CURDATE(), %s, %s, %s, %s, NOW())
        """, (user_id, oil_id, reason, oil_desc, source if source in ('day', 'now') else None))
        conn.commit()
        return cur.rowcount
    finally:
        try: conn.close()
        except: pass

def list_today_recos(user_id: int | str):
    """取今天所有推薦清單（含油名與價格），給前端列表用。"""
    conn = get_db_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute("""
            SELECT r.oil_id,
                   o.name AS oil,
                   o.price,
                   r.reason,
                   r.oil_desc,
                   r.source,
                   r.created_at
            FROM user_daily_oil_recos r
            JOIN oil o ON o.id = r.oil_id
            WHERE r.user_id = %s AND r.reco_date = CURDATE()
            ORDER BY r.created_at DESC
        """, (user_id,))
        return cur.fetchall()
    finally:
        try: conn.close()
        except: pass

# ====== 推薦兩格策略：Day 為主 + Now 為輔，合併分析 ======

def _get_today_day_entry_text(user_id: str) -> str:
    """抓今天的 Day 內容（僅 1 筆）。"""
    conn = get_db_connection()
    if conn is None:
        return ""
    try:
        with conn.cursor(dictionary=True) as cur:
            cur.execute("""
                SELECT content
                FROM diaries
                WHERE user_id=%s AND DATE(create_at)=CURDATE()
                ORDER BY create_at ASC
                LIMIT 1
            """, (user_id,))
            row = cur.fetchone()
            return (row or {}).get('content') or ""
    except Exception:
        return ""
    finally:
        try: conn.close()
        except: pass


def _get_today_now_text(user_id: str) -> str:
    """把今天所有 Now 的 note 串起來供語義檢索/LLM 參考。"""
    conn = get_db_connection()
    if conn is None:
        return ""
    try:
        with conn.cursor(dictionary=True) as cur:
            cur.execute("""
                SELECT note
                FROM now
                WHERE user_id=%s AND DATE(create_at)=CURDATE()
                ORDER BY create_at ASC
            """, (user_id,))
            notes = [ (r.get('note') or "").strip() for r in cur.fetchall() ]
            return "\n".join([n for n in notes if n])
    except Exception:
        return ""
    finally:
        try: conn.close()
        except: pass


def _embed_and_candidates(text: str, n_results: int=8) -> tuple[list[str], list[str]]:
    """向量查詢候選文件與名稱（名稱=文件第一段『名稱：描述…』的名稱）"""
    qvec = embed_text(text)
    results = col.query(query_embeddings=[qvec], n_results=n_results)
    docs = results.get('documents', [[]])[0]
    names = [d.split('：', 1)[0].strip() for d in docs]
    return docs, names


def _llm_pick_oils(context_text: str, cand_docs: list[str], k: int=1) -> tuple[list[str], list[str]]:
    """請 LLM 從候選中選 k 支，回傳 (names, reasons) 等長陣列。"""
    candidates = "\n".join(f"{i+1}. {d}" for i, d in enumerate(cand_docs))
    sys = (
        "你是一位芳療專家。你只能從候選名單中選出精油，"
        "並以 JSON 陣列輸出，每個元素格式："
        "{\"oil\":\"精油名稱\",\"reason\":\"推薦理由（至少20字）\"}。"
        "不得選名單以外的名稱。陣列長度必須等於請求的數量。"
        "分析時，請以【今日主要日記 (Day)】的內容為主要判斷依據，"
        "並以【今日即時紀錄 (Moments)】為輔助參考。"
    )
    messages = [
        {"role": "system", "content": sys + f"\n候選精油：\n{candidates}"},
        {"role": "user", "content": f"請選出 {k} 款最適合的精油。以下是今日內容：\n{context_text}"}
    ]
    payload = {'model': 'gemma3:12b', 'messages': messages, 'stream': False}
    res = requests.post(OLLAMA_CHAT_URL, json=payload, timeout=180)
    res.raise_for_status()
    content = (res.json().get("message", {}) or {}).get("content", "").strip()

    # 嘗試抓出 JSON 陣列
    m = re.search(r'\[[\s\S]*\]', content)
    if not m:
        # fallback：抓第一個物件
        m = re.search(r'\{[\s\S]*\}', content)
        if not m:
            raise RuntimeError(f"LLM 回傳不可解析：{content[:200]}")
        arr = [json.loads(m.group(0))]
    else:
        arr = json.loads(m.group(0))

    names = []
    reasons = []
    for obj in arr:
        name = (obj.get("oil") or "").strip()
        reason = (obj.get("reason") or "").strip()
        if name:
            names.append(name)
            reasons.append(reason or "與今日內容高度相關，適合舒緩情緒。")

    # 尺寸防呆：不足就截/補空字串
    names = names[:k] + [""]*(k - len(names))
    reasons = reasons[:k] + [""]*(k - len(reasons))
    return names, reasons


def _find_oil_id_and_descs(names: list[str], cand_docs: list[str]) -> tuple[dict, dict]:
    """把名稱 -> (id, 描述) 映射找出來（描述從 cand_docs 取第一個匹配）。"""
    id_map = {}
    desc_map = {}
    if not names:
        return id_map, desc_map

    # 先湊描述
    for nm in names:
        desc = next((d for d in cand_docs if d.startswith(nm)), "")
        desc_map[nm] = desc or "查無精油功效"

    # 再查 DB 拿 id
    conn = get_db_connection()
    if conn is None:
        # 沒 DB 就讓 id 都缺失，呼叫端需要 try/except
        return id_map, desc_map
    try:
        with conn.cursor(dictionary=True) as cur:
            qmarks = ",".join(["%s"]*len(names))
            cur.execute(f"SELECT id, name FROM oil WHERE name IN ({qmarks})", tuple(names))
            for row in cur.fetchall():
                id_map[row['name']] = int(row['id'])
        return id_map, desc_map
    finally:
        try: conn.close()
        except: pass


def _replace_today_recos(user_id: str, pairs: list[tuple[int, str, str, str]]):
    """
    【新】覆蓋今天所有的推薦（最多 2 筆）。
    使用 source=NULL 或 'combined' 來標記（這裡使用 NULL）。
    pairs: [(oil_id, name, reason, desc), ...]
    """
    conn = get_db_connection()
    if conn is None:
        return
    try:
        with conn.cursor() as cur:
            # 清掉今天所有推薦
            cur.execute("""
                DELETE FROM user_daily_oil_recos
                WHERE user_id=%s AND reco_date=CURDATE()
            """, (user_id,))
            
            # 插回最多兩筆
            for oil_id, _nm, reason, desc in pairs[:2]:
                cur.execute("""
                    INSERT INTO user_daily_oil_recos
                        (user_id, reco_date, oil_id, reason, oil_desc, source, created_at)
                    VALUES (%s, CURDATE(), %s, %s, %s, NULL, NOW())
                """, (user_id, oil_id, reason, desc))
            conn.commit()
    finally:
        try: conn.close()
        except: pass

@app.route('/recommend_today_oil', methods=['GET'])
def recommend_today_oil():
    """
    兩格制（新）：
      - 每次觸發（無論 Day 或 Now），都重新抓取今天 *所有* Day 和 Now 內容。
      - Day 內容權重 > Now 內容。
      - 合併分析後，LLM 挑選 2 支精油。
      - 刪除今天所有舊推薦，寫入這 2 支新推薦。
    每天換日清空：沿用 purge_outdated_recos。
    """

    def _json_error(msg: str, code: int = 400):
        app.logger.warning(f"/recommend_today_oil error: {msg}")
        return jsonify({"status": "error", "error": msg}), code

    # ★ 1) 參數解析：user_id 轉 int
    user_id = request.args.get('user_id', type=int)
    # source = (request.args.get('source') or '').strip().lower()  # 'day' | 'now' (不再需要 source)
    if not user_id:
        return _json_error("請帶上 user_id（必須為整數）")
    # if source not in ('day', 'now'): (不再需要 source)
    #     return _json_error("source 只能為 day 或 now")

    # ★ 2) 先清掉非今日資料（若失敗回 500）
    try:
        purge_outdated_recos(user_id)
    except Exception as e:
        app.logger.exception("purge_outdated_recos failed")
        return _json_error(f"清理舊推薦失敗: {e}", 500)

    # ★ 3) 獲取今天所有 Day 和 Now 的內容
    try:
        day_text = _get_today_day_entry_text(user_id)
        now_text = _get_today_now_text(user_id)
    except Exception as e:
        app.logger.exception("Failed to fetch today's entries")
        return _json_error(f"讀取今日紀錄失敗: {e}", 500)

    if not day_text and not now_text:
        return _json_error("今天沒有任何 Day 或 Now 紀錄，無法產生推薦")

    # ★ 4) 組合帶有權重提示的上下文
    context_parts = []
    if day_text:
        context_parts.append(f"【今日主要日記 (Day)】\n{day_text}")
    if now_text:
        context_parts.append(f"【今日即時紀錄 (Moments)】\n{now_text}")
    context_text = "\n\n".join(context_parts)

    # ★ 5) 向量檢索候選
    try:
        cand_docs, cand_names = _embed_and_candidates(context_text, n_results=8)
    except Exception as e:
        app.logger.exception("_embed_and_candidates failed (combined)")
        return _json_error(f"候選產生失敗: {e}", 500)

    # ★ 6) LLM 挑選 2 支
    try:
        # 請求 k=2
        oils, reasons = _llm_pick_oils(context_text, cand_docs, k=2)
    except Exception as e:
        app.logger.exception("_llm_pick_oils failed (combined)")
        return _json_error(f"推薦失敗（LLM）: {e}", 500)

    oils = [ (o or "").strip() for o in (oils or []) if (o or "").strip() ]
    reasons = reasons or []
    if len(reasons) < len(oils):
        # 補齊理由長度
        reasons += ["這款精油與今日紀錄高度相關。"] * (len(oils) - len(reasons))

    # ★ 7) 查找精油 ID 和描述
    try:
        ids, name2desc = _find_oil_id_and_descs(oils, cand_docs)
    except Exception as e:
        app.logger.exception("_find_oil_id_and_descs failed (combined)")
        return _json_error(f"查詢精油資料失敗: {e}", 500)

    # ★ 8) 組合並確保唯一性
    pairs: list[tuple[int, str, str, str]] = []
    chosen_ids = set()
    
    # 先放入 LLM 挑的
    for name, reason in zip(oils, reasons):
        oid = ids.get(name)
        if not isinstance(oid, int):
            continue
        if oid in chosen_ids: # 確保 LLM 給的兩支不重複
            continue
        pairs.append((oid, name, reason or "這款精油與今日紀錄高度相關。", name2desc.get(name, "查無精油功效")))
        chosen_ids.add(oid)

    # 不足 2 支 → 從候選(cand_names)補
    cand_names = [ (n or "").strip() for n in (cand_names or []) if (n or "").strip() ]
    for nm in cand_names:
        if len(pairs) >= 2:
            break
        try:
            # 這裡再次查詢是為了確保 cand_names 裡的名稱能對應到 ID
            nid_map, descs = _find_oil_id_and_descs([nm], cand_docs)
            nid = nid_map.get(nm)
            if not isinstance(nid, int):
                continue
            if nid in chosen_ids: # 確保不跟 LLM 選的重複
                continue
            pairs.append((nid, nm, "這款精油與今日紀錄高度相關。", descs.get(nm, "查無精油功效")))
            chosen_ids.add(nid)
        except Exception:
            continue # 忽略查找失敗的候選

    if not pairs:
        return _json_error("無法產生可用的油品推薦（可能候選庫無對應名稱或 ID 對不上）", 500)

    # ★ 9) 寫入資料庫（覆蓋今天所有）
    try:
        _replace_today_recos(user_id, pairs[:2])
    except Exception as e:
        app.logger.exception("_replace_today_recos failed")
        return _json_error(f"寫入推薦失敗: {e}", 500)

    # ★ 10) 回傳
    rows = list_today_recos(user_id) # 重新讀取，確保拿到剛寫入的
    return jsonify({
        "status": "refreshed",
        "items": [
            {"oil_id": p[0], "oil": p[1], "reason": p[2], "oil_desc": p[3]}
            for p in pairs[:2]
        ],
        "all": rows
    }), 200

@app.route('/today_oil_recos', methods=['GET'])
def today_oil_recos():  
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({"error": "請帶上 user_id"}), 400

    # 也可順手清一次舊資料（保險）
    try:
        purge_outdated_recos(user_id)
    except Exception as e:
        return jsonify({"error": f"清理舊推薦失敗: {e}"}), 500

    try:
        rows = list_today_recos(user_id)
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": f"取得今日推薦清單失敗: {e}"}), 500

@app.route('/search_diary_entries', methods=['GET'])
def search_diary_entries():
    user_id = session.get('user_id') or request.args.get('user_id')
    query = request.args.get('query', '').strip()

    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400
    if not query:
        return jsonify({'error': 'Missing query'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    cursor = None
    try:
        cursor = connection.cursor(dictionary=True)
        wildcard = f"%{query}%"

        # 一次把兩個表合併查詢，並在 SQL 層排序
        sql = """
        SELECT *
        FROM (
            SELECT
                d.id,
                d.user_id,
                d.content AS mood_text,
                COALESCE(d.joy, 0)      AS joy,
                COALESCE(d.sadness, 0)  AS sadness,
                COALESCE(d.anger, 0)    AS anger,
                COALESCE(d.positive, 0) AS positive,
                COALESCE(d.anxiety, 0)  AS anxiety,
                COALESCE(d.exhaust, 0)  AS exhaust,
                d.color_mix             AS mixed_color,
                d.create_at,
                d.is_english,
                d.details,
                'Day'                   AS entry_type
            FROM diaries d
            WHERE d.user_id = %s AND (d.content LIKE %s OR d.details LIKE %s)

            UNION ALL

            SELECT
                n.id,
                n.user_id,
                n.note                 AS mood_text,
                COALESCE(n.joy, 0)     AS joy,
                COALESCE(n.sadness, 0) AS sadness,
                COALESCE(n.anger, 0)   AS anger,
                COALESCE(n.positive, 0)AS positive,
                COALESCE(n.anxiety, 0) AS anxiety,
                COALESCE(n.exhaust, 0) AS exhaust,
                NULL                   AS mixed_color,
                n.create_at,
                n.is_english,
                n.details,
                'Moment'               AS entry_type
            FROM now n
            WHERE n.user_id = %s AND (n.note LIKE %s OR n.details LIKE %s)
        ) AS entries
        ORDER BY create_at DESC
        """

        params = (user_id, wildcard, wildcard, user_id, wildcard, wildcard)
        cursor.execute(sql, params)
        rows = cursor.fetchall()

        # 組裝回傳格式
        results = []
        for e in rows:
            is_eng = bool(e.get('is_english'))
            results.append({
                'id': e['id'],
                'user_id': e['user_id'],
                'mood_text': e['mood_text'],
                'mixed_color': e['mixed_color'],     # Day 有值、Moment 為 None
                'create_at': e['create_at'],         # 原始時間物件（若前端要字串，下方也有 entry_date/time）
                'is_english': e['is_english'],
                'details': e.get('details'),
                'entry_type': e['entry_type'],
                'entry_date': e['create_at'].date().isoformat() if e['create_at'] else None,
                'entry_time': e['create_at'].strftime('%H:%M:%S') if e['create_at'] else None,
                'emotions': [
                    {'emotion': ('快樂' if not is_eng else 'joy'),      'intensity': float(e['joy'])},
                    {'emotion': ('悲傷' if not is_eng else 'sadness'),   'intensity': float(e['sadness'])},
                    {'emotion': ('憤怒' if not is_eng else 'anger'),     'intensity': float(e['anger'])},
                    {'emotion': ('積極' if not is_eng else 'positive'),  'intensity': float(e['positive'])},
                    {'emotion': ('焦慮' if not is_eng else 'anxiety'),   'intensity': float(e['anxiety'])},
                    {'emotion': ('疲憊' if not is_eng else 'exhaust'),   'intensity': float(e['exhaust'])},
                ]
            })

        return jsonify(results), 200

    except Error as e:
        return jsonify({'error': f'Failed to search diary entries: {e}'}), 500
    finally:
        try:
            if cursor is not None:
                cursor.close()
        except Exception:
            pass
        try:
            connection.close()
        except Exception:
            pass

# ============ 啟動 Flask 伺服器 ============
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)