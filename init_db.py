"""Creates tables, loads sample data and sets demo passwords. Run once: python init_db.py"""
import os, psycopg2
from werkzeug.security import generate_password_hash

DB = dict(dbname=os.getenv("DB_NAME", "smartfix"), user=os.getenv("DB_USER", "postgres"),
          password=os.getenv("DB_PASSWORD", "postgres"), host=os.getenv("DB_HOST", "localhost"),
          port=os.getenv("DB_PORT", "5432"))

conn = psycopg2.connect(**DB)
with conn, conn.cursor() as cur:
    for f in ("schema.sql", "sample_data.sql"):
        cur.execute(open(f, encoding="utf-8").read())
    h = generate_password_hash("password123")
    for t in ("customer", "worker", "admin"):
        cur.execute(f"UPDATE {t} SET password_hash=%s", (h,))
conn.close()
print("Database ready. All demo accounts use password: password123")
