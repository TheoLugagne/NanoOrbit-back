from functools import wraps

from flask import jsonify, session


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("username"):
            return jsonify(error="Non authentifié"), 401
        return view(*args, **kwargs)

    return wrapped


def back_office_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not session.get("username"):
            return jsonify(error="Non authentifié"), 401
        if session.get("role") == "analyste":
            return jsonify(error="Accès back-office refusé pour votre profil."), 403
        return view(*args, **kwargs)

    return wrapped


def role_required(*roles, error_message="Accès refusé"):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if not session.get("username"):
                return jsonify(error="Non authentifié"), 401
            if session.get("role") not in roles:
                return jsonify(error=error_message), 403
            return view(*args, **kwargs)

        return wrapped

    return decorator
