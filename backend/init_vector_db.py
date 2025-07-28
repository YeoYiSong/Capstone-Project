import os
import json
import requests
import chromadb

# ✅ 設定向量資料庫儲存路徑
DB_DIR = r"d:/大四專題/oil/oilmodule/backend/chroma_db"
os.makedirs(DB_DIR, exist_ok=True)

# ✅ PersistentClient（新版ChromaDB推薦）
client = chromadb.PersistentClient(path=DB_DIR)

# ✅ 刪除舊的 collection（如果存在）
try:
    client.delete_collection(name="essential_oils")
    print("✅ 已刪除舊的 essential_oils collection")
except Exception as e:
    print(f"⚠️ 無法刪除 collection：{e}")

# ✅ 建立新的 collection
col = client.get_or_create_collection(name="essential_oils")

# ✅ 設定嵌入模型
OLLAMA_EMBED_URL = 'http://localhost:11434/api/embed'
MODEL_NAME = 'nn200433/text2vec-bge-large-chinese'

def embed_text(text):
    res = requests.post(OLLAMA_EMBED_URL, json={
        'model': MODEL_NAME,
        'input': text
    })
    data = res.json()
    vecs = data.get('embeddings') or data.get('embedding')
    if vecs is None:
        raise RuntimeError(f"嵌入回傳格式異常：{data}")
    return vecs[0] if isinstance(vecs[0], list) else vecs

# ✅ 讀取 oils.json
with open('oils1.json', 'r', encoding='utf-8') as f:
    oils = json.load(f)

# ✅ 批次嵌入所有精油文本
texts = [oil['name'] + '：' + '、'.join(oil['effects']) for oil in oils]
ids = [oil['name'] for oil in oils]

print("🔄 開始產生所有精油的語意向量（嵌入）...")
embeddings = []
for idx, text in enumerate(texts):
    try:
        vec = embed_text(text)
        embeddings.append(vec)
        print(f"✅ 已嵌入：{ids[idx]}")
    except Exception as e:
        print(f"❌ {ids[idx]} 嵌入失敗：{e}")
        embeddings.append([0.0]*768) # 若失敗，用零向量避免報錯

print("📝 開始批次寫入 ChromaDB ...")
col.add(
    ids=ids,
    embeddings=embeddings,
    documents=texts
)
print("🎉 向量資料庫初始化完成，資料已儲存在：", os.path.abspath(DB_DIR))
