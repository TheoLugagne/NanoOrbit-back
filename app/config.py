import os

from dotenv import load_dotenv

load_dotenv()


def _parse_cors_origins() -> list[str]:
    raw = os.getenv("CORS_ORIGINS", "").strip()
    if raw:
        return [origin.strip() for origin in raw.split(",") if origin.strip()]

    origins = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:4173",
        "https://nano-orbite.tlugagne.live",
        "http://nano-orbite.tlugagne.live",
    ]
    front = os.getenv("FRONTEND_ORIGIN", "").strip()
    if front and front not in origins:
        origins.append(front)
    return origins


class Config:
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "change-me-in-production")
    FLASK_ENV = os.getenv("FLASK_ENV", "development")
    CORS_ORIGINS = _parse_cors_origins()
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = os.getenv("SESSION_COOKIE_SAMESITE", "None")
    SESSION_COOKIE_SECURE = os.getenv("SESSION_COOKIE_SECURE", "true").lower() == "true"
    MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
    MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "nanoOrbit_db")
    MYSQL_USER = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
