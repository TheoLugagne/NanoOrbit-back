from flask import Flask, jsonify, send_from_directory, session
from flask_cors import CORS
from werkzeug.exceptions import HTTPException

from app.api import front_bp
from app.auth import auth_bp
from app.config import Config
from app import db
from app.middleware.auth import login_required


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    CORS(app, supports_credentials=True)

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(front_bp, url_prefix="/api")

    @app.get("/")
    def index():
        return send_from_directory(app.static_folder, "index.html")

    @app.errorhandler(HTTPException)
    def handle_http_exception(error):
        return jsonify(error=error.description or error.name), error.code

    @app.errorhandler(Exception)
    def handle_exception(error):
        return jsonify(error="Erreur interne du serveur"), 500

    return app