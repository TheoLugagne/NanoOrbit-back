import re
from flask import jsonify, session
from mysql.connector import Error

from app import db
from app.auth.services import REV_USER_MAPPING


_PERMISSION_ERRORS = frozenset({1044, 1142, 1143})
_CONSTRAINT_ERRORS = frozenset({1062, 3819, 4025, 1690})
_DUPLICATE_ENTRY = re.compile(
    r"Duplicate entry '([^']+)' for key '([^']+)'",
    re.IGNORECASE,
)

_EMBARQUE_PK_ENTRY = re.compile(r"^(SAT-[^-]+)-(.+)$")

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

def embarquement_conflict_message(ref_instrument: str, id_satellite: str, other_satellite: str | None = None) -> str:
    id_satellite: str,
    other_satellite: str | None = None) -> str:
    if other_satellite and other_satellite != id_satellite:
        return f"RG-I03 : l'instrument « {ref_instrument} » est déjà embarqué f"sur le satellite « {other_satellite} »."
    return f"L'instrument « {ref_instrument} » est déjà embarqué f"sur le satellite « {id_satellite} »."

def _error_text(error: Error) -> str:
    parts: list[str] = []
    if error.msg:
        parts.append(str(error.msg))
    if error.args:
        for arg in error.args:
            text = str(arg)
            if text and text not in parts:
                parts.append(text)
    if not parts:
        parts.append(str(error))
    return " ".join(parts)

def _constraint_error_message(error: Error) -> str | None:
    msg = _error_text(error)
    if error.errno == 1644 and "RG-I03" in msg:
        return _RG_I03_MESSAGE
    duplicate = _DUPLICATE_ENTRY.search(msg)
    if duplicate:
        entry, key = duplicate.groups()
        key_name = key.rsplit(".", 1)[-1].lower()
        if key_name == "uk_rg_i03_ref_instrument":
            return embarquement_conflict_message(entry, None)
        if key_name == "primary":
            entry_match = _EMBARQUE_PK_ENTRY.match(entry)
            if entry_match:
                id_satellite, ref_instrument = entry_match.groups()
                if not ref_instrument.startswith("MSN-"):
                    return embarquement_conflict_message(
                        ref_instrument=ref_instrument,
                        id_satellite=id_satellite,
                    )

    if "uk_rg_i03_ref_instrument" in msg.lower():
        return embarquement_conflict_message(entry, None)
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


