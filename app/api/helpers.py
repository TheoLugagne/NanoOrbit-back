import re

from flask import jsonify, session
from mysql.connector import Error

from app import db
from app.auth.services import REV_USER_MAPPING

_PERMISSION_ERRORS = frozenset({1044, 1142, 1143})
_CONSTRAINT_ERRORS = frozenset({1062, 3819, 4025, 1690})
_RG_I03_DUPLICATE = re.compile(
    r"Duplicate entry '([^']+)' for key 'uk_rg_i03_ref_instrument'"
)
_RG_I03_MESSAGE = (
    "RG-I03 : cet instrument est déjà embarqué sur un autre satellite."
)


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


def _constraint_error_message(error: Error) -> str | None:
    msg = error.msg or ""

    if error.errno == 1644 and "RG-I03" in msg:
        return _RG_I03_MESSAGE

    match = _RG_I03_DUPLICATE.search(msg)
    if match:
        ref_instrument = match.group(1)
        return (
            f"RG-I03 : l'instrument « {ref_instrument} » est déjà embarqué "
            "sur un autre satellite."
        )

    if "uk_rg_i03_ref_instrument" in msg:
        return _RG_I03_MESSAGE

    return None


def _handle_db_error(error: Error, fallback_message: str):
    if error.errno in _PERMISSION_ERRORS:
        return jsonify(error="Droits insuffisants sur cette ressource"), 403
    if error.errno in _CONSTRAINT_ERRORS:
        friendly_message = _constraint_error_message(error)
        return jsonify(
            error=friendly_message
            or error.msg
            or "Données invalides ou contrainte violée"
        ), 400
    if error.errno == 1644:
        friendly_message = _constraint_error_message(error)
        return jsonify(error=friendly_message or error.msg or "Opération refusée"), 400
    return jsonify(error=fallback_message), 500
