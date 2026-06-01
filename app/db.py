import mysql.connector
from mysql.connector import Error

from app.config import Config


def get_connection(username: str, password: str):
    return mysql.connector.connect(
        host=Config.MYSQL_HOST,
        port=Config.MYSQL_PORT,
        database=Config.MYSQL_DATABASE,
        user=username,
        password=password,
    )


def test_connection(username: str, password: str) -> bool:
    try:
        conn = get_connection(username, password)
    except Error:
        return False

    try:
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT 1")
            return cursor.fetchone() is not None
        finally:
            cursor.close()
    except Error:
        return False
    finally:
        conn.close()


def query(username: str, password: str, sql: str, params=None) -> list[dict]:
    conn = get_connection(username, password)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(sql, params or ())
            if cursor.with_rows:
                return cursor.fetchall()
            return []
        finally:
            cursor.close()
    finally:
        conn.close()
