from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # 允許跨域請求

# 資料庫連線配置（根據你的 XAMPP 設定調整）
db_config = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '',  # 根據你的 XAMPP 設定修改
    'database': 'demomaily_db'
}

def get_db_connection():
    try:
        connection = mysql.connector.connect(**db_config)
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

@app.route('/save_diary_entry', methods=['POST'])
def save_diary_entry():
    data = request.get_json()
    date = data.get('date')
    type = data.get('type')
    emotions = json.dumps(data.get('emotions'))  # 將 emotions 轉為 JSON 字符串
    mixed_color = data.get('mixedColor')
    mood_text = data.get('moodText')
    details = data.get('details')
    is_english = 1 if data.get('isEnglish') else 0

    # 解析日期和時間
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)