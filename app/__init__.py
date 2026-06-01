from flask import Flask, jsonify
from flask_cors import CORS

from app.config import Config
from app import db

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    CORS(app, supports_credentials=True)

    if not db.test_connection(app.config['MYSQL_USER'], app.config['MYSQL_PASSWORD']):
        raise Exception("Failed to connect to MySQL database")
    else:
        print("Connected to MySQL database")
        print(db.query(app.config['MYSQL_USER'], app.config['MYSQL_PASSWORD'], "SELECT 1"))

    # @app.errorhandler(Exception)
    # def handle_exception(error):
    #     return jsonify(error=str(error)), 500

    return app


