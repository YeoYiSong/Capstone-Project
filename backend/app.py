from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import json
from datetime import datetime , date ,timedelta

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

#本子功能 _______________________________________________________________________________
@app.route("/diaries/month", methods=["GET"])
def get_month_overview():
    month_str = request.args.get("month","").strip()               # 必填：YYYY-MM
    user_id   = request.args.get("user_id", type=int)   # 可選

    # 1) 驗證月份格式並計算首末日
    try:
        first_day = datetime.strptime(month_str + "-01", "%Y-%m-%d").date()
        # 下個月 1 號 – 1 天 = 本月最後一天
        next_month_first = (
            date(first_day.year + 1, 1, 1)
            if first_day.month == 12
            else date(first_day.year, first_day.month + 1, 1)
        )
        last_day = next_month_first - timedelta(days=1)
    except Exception:
        return jsonify({"error": "month 參數格式錯誤，請用 YYYY-MM"}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "資料庫連線失敗"}), 500

    try:
        cur = conn.cursor(dictionary=True)

        # 2) 動態條件
        conds  = ["DATE(create_at) BETWEEN %s AND %s"]
        params = [first_day, last_day]

        if user_id is not None:
            conds.append("user_id = %s")
            params.append(user_id)

        # 3) 直接撈：一天只有一筆，不需 GROUP
        sql = f"""
            SELECT DATE(create_at) AS entry_date, color_mix
            FROM diaries
            WHERE {' AND '.join(conds)}
            ORDER BY entry_date
        """
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()

        # 4) 日期物件轉 'YYYY-MM-DD'
        for r in rows:
            r["entry_date"] = r["entry_date"].isoformat()

        return jsonify(rows), 200

    except Error as e:
        return jsonify({"error": f"查詢失敗: {e}"}), 500
    finally:
        cur.close()
        conn.close()

# -------------------------------
# 單日 detail：回所有欄位（含 content）
# -------------------------------
@app.route("/diaries/day", methods=["GET"])
def get_day_detail():
    # ① 讀參數（date 一定會有，但仍做格式驗證，以免手滑）
    day_str = request.args.get("date")          # 例如 2025-06-24
    user_id = request.args.get("user_id", type=int, default=None)

    try:
        target_day = date.fromisoformat(day_str)     # 'YYYY-MM-DD' → date 物件
    except Exception:
        return jsonify({"error": "date 格式錯誤，請用 YYYY-MM-DD"}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({"error": "資料庫連線失敗"}), 500

    try:
        cur = conn.cursor(dictionary=True)

        # ② 組 SQL
        conds = ["DATE(create_at) = %s"]
        params = [target_day]

        if user_id is not None:
            conds.append("user_id = %s")
            params.append(user_id)

        sql = f"""
            SELECT content, color_mix, create_at
            FROM diaries
            WHERE {' AND '.join(conds)}
            ORDER BY create_at DESC
        """
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()

        # ③ create_at 物件 → 'YYYY-MM-DD' 或 'YYYY-MM-DDTHH:MM:SS'
        for r in rows:
            ca = r["create_at"]
            # DATE → date 物件；DATETIME/TIMESTAMP → datetime 物件
            r["create_at"] = ca.isoformat() if hasattr(ca, "isoformat") else str(ca)

        return jsonify(rows), 200

    except Error as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)