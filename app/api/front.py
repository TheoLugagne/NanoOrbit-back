from flask import Blueprint, jsonify, session
from mysql.connector import Error

from app import db
from app.middleware.auth import login_required
from app.auth.services import REV_USER_MAPPING

front_bp = Blueprint("front", __name__)


@front_bp.get("/satellites")
@login_required
def satellites():
    print(f"Session: {session}")
    try:
        print(f"Session username: {session['username']}")
        print(f"Session password: {session['password']}")
        rows = db.query(
            REV_USER_MAPPING[session["username"]],
            session["password"],
            "SELECT * FROM VUE_SATELLITES_OPERATIONNELS",
        )
        print(f"Rows: {rows}")
        return jsonify(rows), 200
    except Error as error:
        print(f"Error: {error}")
        if error.errno in {1044, 1142, 1143}:
            return jsonify(error="Droits insuffisants sur cette ressource"), 403
        return jsonify(error="Erreur lors de la lecture des satellites"), 500
