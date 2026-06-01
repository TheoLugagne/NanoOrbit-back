from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

from app.auth import auth_bp
from app.config import Config
from app import db

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    CORS(app, supports_credentials=True)

    app.register_blueprint(auth_bp, url_prefix="/api/auth")

    @app.get("/")
    def index():
        return send_from_directory(app.static_folder, "index.html")

    # @app.errorhandler(Exception)
    # def handle_exception(error):
    #     return jsonify(error=str(error)), 500

    return app


