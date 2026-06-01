import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "change-me-in-production")
    FLASK_ENV = os.getenv("FLASK_ENV", "development")
    MYSQL_HOST = os.getenv("MYSQL_HOST", "mysql-tlugagne.alwaysdata.net")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
    MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "tlugagne_tp")
    MYSQL_USER = os.getenv("MYSQL_USER", "tlugagne")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "RRipuCLSTy9esTj")
