from flask import Blueprint, jsonify, request, session
from mysql.connector import Error

from app import db
from app.middleware.auth import login_required
from app.auth.services import REV_USER_MAPPING

front_bp = Blueprint("front", __name__)

_FENETRE_STATUTS = frozenset({"Réalisée", "Planifiée", "Échouée"})


def _front_query(sql: str, params=None, *, error_message: str):
    user = REV_USER_MAPPING[session["username"]]
    pwd = session["password"]
    try:
        print(sql)
        print(params)
        return db.query(user, pwd, sql, params), None
    except Error as error:
        if error.errno in {1044, 1142, 1143}:
            return None, (jsonify(error="Droits insuffisants sur cette ressource"), 403)
        return None, (jsonify(error=error_message), 500)


@front_bp.get("/satellites")
@login_required
def satellites():
    rows, err = _front_query(
        "SELECT * FROM VUE_SATELLITES_OPERATIONNELS",
        error_message="Erreur lors de la lecture des satellites",
    )
    if err:
        return err
    return jsonify(rows), 200


@front_bp.get("/communications")
@login_required
def communications():
    rows, err = _front_query(
        "SELECT * FROM VUE_BILAN_COMMUNICATIONS ORDER BY volume_total DESC",
        error_message="Erreur lors de la lecture des communications",
    )
    if err:
        return err
    return jsonify(
        items=rows,
        satellite_plus_actif=rows[0] if rows else None,
    ), 200


@front_bp.get("/missions")
@login_required
def missions():
    rows, err = _front_query(
        "SELECT * FROM VUE_TABLEAU_DE_BORD_MISSIONS",
        error_message="Erreur lors de la lecture des missions",
    )
    print(rows)
    print(err)
    if err:
        return err
    for row in rows:
        if "sous_dotee" not in row:
            row["sous_dotee"] = (
                row["nb_sat_operationnels"] < row["nb_satellites"]
            )
    return jsonify(rows), 200


@front_bp.get("/alertes")
@login_required
def alertes():
    rows, err = _front_query(
        "SELECT * FROM VUE_ALERTES_INSTRUMENTS ORDER BY priorite DESC",
        error_message="Erreur lors de la lecture des alertes",
    )
    print(rows)
    if err:
        return err
    compteur_critique = sum(1 for r in rows if r.get("priorite") == "CRITIQUE")
    return jsonify(compteur_critique=compteur_critique, items=rows), 200


@front_bp.get("/fenetres/historique")
@login_required
def fenetres_historique():
    id_sat = (request.args.get("id_satellite") or "").strip() or None
    statut = (request.args.get("statut") or "").strip() or None
    if statut is not None and statut not in _FENETRE_STATUTS:
        return jsonify(error="Statut invalide"), 400

    conditions = []
    params = []
    if id_sat is not None:
        conditions.append("f.id_satellite = %s")
        params.append(id_sat)
    if statut is not None:
        conditions.append("f.statut = %s")
        params.append(statut)

    where_clause = " AND ".join(conditions) if conditions else "1=1"

    rows, err = _front_query(
        f"""
        SELECT
            f.id_fenetre,
            f.datetime_debut AS date_heure_debut,
            f.duree AS duree_secondes,
            s.id_satellite,
            s.nom_satellite,
            st.code_station AS id_station,
            st.nom_station,
            f.elevation_max AS elevation_max_deg,
            f.volume_donnees AS volume_donnees_mo,
            f.statut
        FROM FENETRE_COMM f
        INNER JOIN SATELLITE s ON f.id_satellite = s.id_satellite
        INNER JOIN STATION_SOL st ON f.code_station = st.code_station
        WHERE {where_clause}
        ORDER BY f.datetime_debut DESC
        """,
        tuple(params) if params else None,
        error_message="Erreur lors de la lecture de l'historique des fenêtres",
    )
    if err:
        return err
    return jsonify(rows), 200
