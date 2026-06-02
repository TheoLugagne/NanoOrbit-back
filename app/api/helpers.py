from flask import jsonify, session
from mysql.connector import Error

from app import db
from app.auth.services import REV_USER_MAPPING

_PERMISSION_ERRORS = frozenset({1044, 1142, 1143})
_CONSTRAINT_ERRORS = frozenset({1062, 3819, 4025, 1690})


def session_credentials():
    return REV_USER_MAPPING[session["username"]], session["password"]


def db_query(sql: str, params=None, *, error_message: str):
    user, pwd = session_credentials()
    try:
        return db.query(user, pwd, sql, params), None
    except Error as error:
        return None, _handle_db_error(error, error_message)


def db_execute(sql: str, params=None, *, error_message: str):
    user, pwd = session_credentials()
    try:
        return db.execute(user, pwd, sql, params), None
    except Error as error:
        return None, _handle_db_error(error, error_message)


def _handle_db_error(error: Error, fallback_message: str):
    if error.errno in _PERMISSION_ERRORS:
        return jsonify(error="Droits insuffisants sur cette ressource"), 403
    if error.errno in _CONSTRAINT_ERRORS:
        return jsonify(error=error.msg or "Données invalides ou contrainte violée"), 400
    if error.errno == 1644:
        return jsonify(error=error.msg or "Opération refusée"), 400
    return jsonify(error=fallback_message), 500
