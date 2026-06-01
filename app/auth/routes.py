from flask import Blueprint, jsonify, request, session

from app.auth.services import authenticate, build_auth_session

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")

    auth_session = authenticate(username, password)
    if auth_session is None:
        return jsonify(error="Identifiants invalides"), 401

    session.clear()
    session["username"] = username
    session["password"] = password
    session["role"] = auth_session["role"]

    return jsonify(auth_session), 200


@auth_bp.post("/logout")
def logout():
    session.clear()
    return jsonify(message="Déconnecté"), 200


@auth_bp.get("/me")
def me():
    username = session.get("username")
    role = session.get("role")
    if not username or not role:
        return jsonify(error="Non authentifié"), 401

    return jsonify(build_auth_session(username, role)), 200
