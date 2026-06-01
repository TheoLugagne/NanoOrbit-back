from app import db

ROLE_MAPPING = {
    "analyste_data": "analyste",
    "operateur_sat": "operateur",
    "resp_mission": "responsable",
    "admin_nano": "admin",
}

USER_MAPPING = {
    "tlugagne_analyst": "analyste_data",
    "tlugagne_operateur": "operateur_sat",
    "tlugagne_responsable": "resp_mission",
    "tlugagne": "admin_nano",
}

REV_USER_MAPPING = {v: k for k, v in USER_MAPPING.items()}

def _can_access_back_office(role: str) -> bool:
    return role != "analyste"

def build_auth_session(username: str, role: str) -> dict:
    can_access_backoffice = _can_access_back_office(role)
    return {
        "username": username,
        "role": role,
        "can_access_backoffice": can_access_backoffice,
        "access": {
            "front_office": True,
            "back_office": can_access_backoffice,
        },
    }

def detect_role(username: str, password: str) -> str | None:
    if username not in ROLE_MAPPING:
        return None
    grantee_pattern = f"%{REV_USER_MAPPING[username]}%"
    rows = db.query(
        REV_USER_MAPPING[username],
        password,
        f"SELECT GRANTEE FROM information_schema.USER_PRIVILEGES WHERE GRANTEE LIKE '{grantee_pattern}'"
    )
    if not rows:
        return None

    return ROLE_MAPPING[username]


def authenticate(username: str, password: str) -> dict | None:
    if not username or not password:
        return None
    if not db.test_connection(REV_USER_MAPPING[username], password):
        return None
    role = detect_role(username, password)
    if role is None:
        return None

    return build_auth_session(username, role)
