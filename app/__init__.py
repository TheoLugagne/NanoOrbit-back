from flask import Flask, jsonify, send_from_directory, session
from flask_cors import CORS
from werkzeug.exceptions import HTTPException, NotFound

from app.api import actions_bp, back_bp, front_bp
from app.auth import auth_bp
from app.config import Config
from app import db
from app.middleware.auth import login_required


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    CORS(
        app,
        supports_credentials=True,
        origins=app.config["CORS_ORIGINS"],
        allow_headers=["Content-Type"],
        methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    )

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(front_bp, url_prefix="/api")
    app.register_blueprint(back_bp, url_prefix="/api/back")
    app.register_blueprint(actions_bp, url_prefix="/api")

    @app.get("/")
    def index():
        return send_from_directory(app.static_folder, "index.html")

    @app.errorhandler(NotFound)
    def handle_not_found(error):
        return jsonify(error="Route API introuvable."), 404

    @app.errorhandler(HTTPException)
    def handle_http_exception(error):
        return jsonify(error=error.description or error.name), error.code

    @app.errorhandler(Exception)
    def handle_exception(error):
        return jsonify(error="Erreur interne du serveur"), 500

    return app