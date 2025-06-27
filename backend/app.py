from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

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
        
#日記模組
@app.route('/save_diary_entry', methods=['POST'])
def save_diary_entry():
    data = request.get_json()
    date = data.get('date')
    type = data.get('type')
    emotions = json.dumps(data.get('emotions'))
    mixed_color = data.get('mixedColor')
    mood_text = data.get('moodText')
    details = data.get('details')
    is_english = 1 if data.get('isEnglish') else 0

    try:
        dt = datetime.fromisoformat(date.replace('Z', '+00:00'))
        entry_date = dt.date().isoformat()
        entry_time = dt.time().strftime('%H:%M:%S')
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor()
        query = """
        INSERT INTO diary_entries (entry_date, entry_time, entry_type, emotions, mixed_color, mood_text, details, is_english)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (entry_date, entry_time, type, emotions, mixed_color, mood_text, details, is_english))
        connection.commit()
        return jsonify({'message': 'Diary entry saved successfully'}), 200
    except Error as e:
        return jsonify({'error': f'Failed to save diary entry: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/get_diary_entries/<date>', methods=['GET'])
def get_diary_entries(date):
    try:
        entry_date = datetime.strptime(date, '%Y-%m-%d').date().isoformat()
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = "SELECT * FROM diary_entries WHERE entry_date = %s"
        cursor.execute(query, (entry_date,))
        entries = cursor.fetchall()
        for entry in entries:
            entry['entry_date'] = entry['entry_date'].isoformat()
            entry['entry_time'] = entry['entry_time'].strftime('%H:%M:%S')
            entry['is_english'] = bool(entry['is_english'])
        return jsonify(entries), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch diary entries: {e}'}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/get_all_diary_entries', methods=['GET'])
def get_all_diary_entries():
    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Failed to connect to database'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = "SELECT * FROM diary_entries"
        cursor.execute(query)
        entries = cursor.fetchall()
        for entry in entries:
            entry['entry_date'] = entry['entry_date'].isoformat()
            entry['entry_time'] = entry['entry_time'].strftime('%H:%M:%S')
            entry['is_english'] = bool(entry['is_english'])
        return jsonify(entries), 200
    except Error as e:
        return jsonify({'error': f'Failed to fetch diary entries: {e}'}), 500
    finally:
        cursor.close()
        connection.close()
#呼吸模組
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
    try:
        entry_date = datetime.strptime(date, '%Y-%m-%d').date().isoformat()
    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400

    connection = get_db_connection()
    if connection is None:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        query = "SELECT * FROM breath_record WHERE DATE(create_at) = %s"
        cursor.execute(query, (entry_date,))
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)


