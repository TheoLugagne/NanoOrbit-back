from flask import Blueprint, jsonify, request

from app.api.helpers import db_execute, db_query
from app.middleware.auth import back_office_required, login_required, role_required

back_bp = Blueprint("back", __name__)
actions_bp = Blueprint("actions", __name__)

_SATELLITE_STATUTS = frozenset({"Opérationnel", "En veille", "Désorbité"})
_INSTRUMENT_ETATS = frozenset({"Nominal", "Dégradé", "Hors service"})

_ERR_STATUT = (
    "Action refusée : seuls operateur_sat et admin_nano "
    "peuvent modifier le statut d'un satellite."
)
_ERR_FENETRE = (
    "Action refusée : seuls operateur_sat et admin_nano "
    "peuvent planifier une fenêtre de communication."
)
_ERR_PARTICIPATION = (
    "Action refusée : seuls resp_mission et admin_nano "
    "peuvent assigner un satellite à une mission."
)
_ERR_DESORBITER = (
    "Action refusée : seul admin_nano peut désorbiter un satellite."
)
_ERR_EMBARQUEMENT = (
    "Action refusée : seuls operateur_sat et admin_nano "
    "peuvent gérer les instruments embarqués."
)


# --- Back-office lecture (GET /api/back/*) ---


@back_bp.get("/satellites")
@login_required
@back_office_required
def list_satellites():
    rows, err = db_query(
        """
        SELECT id_satellite, nom_satellite AS nom, statut
        FROM SATELLITE
        ORDER BY nom_satellite
        """,
        error_message="Erreur lors de la lecture des satellites",
    )
    if err:
        return err
    return jsonify(rows), 200


@back_bp.get("/satellites/operationnels")
@login_required
@back_office_required
def list_satellites_operationnels():
    rows, err = db_query(
        """
        SELECT id_satellite, nom_satellite AS nom
        FROM VUE_SATELLITES_OPERATIONNELS
        ORDER BY nom_satellite
        """,
        error_message="Erreur lors de la lecture des satellites opérationnels",
    )
    if err:
        return err
    return jsonify(rows), 200


@back_bp.get("/stations/actives")
@login_required
@back_office_required
def list_stations_actives():
    rows, err = db_query(
        """
        SELECT code_station AS id_station, nom_station AS nom
        FROM STATION_SOL
        WHERE statut = 'Active'
        ORDER BY nom_station
        """,
        error_message="Erreur lors de la lecture des stations actives",
    )
    if err:
        return err
    return jsonify(rows), 200


@back_bp.get("/missions/actives")
@login_required
@back_office_required
def list_missions_actives():
    rows, err = db_query(
        """
        SELECT id_mission, nom_mission AS nom, zone_geo_cible AS zone_cible
        FROM MISSION
        WHERE statut_mission = 'Active'
        ORDER BY nom_mission
        """,
        error_message="Erreur lors de la lecture des missions actives",
    )
    if err:
        return err
    return jsonify(rows), 200


@back_bp.get("/satellites/<id_satellite>/instruments")
@login_required
@back_office_required
def list_instruments_satellite(id_satellite):
    rows, err = db_query(
        """
        SELECT
            i.ref_instrument AS id_instrument,
            i.modele AS nom,
            i.type_instrument,
            e.etat_fonctionnement
        FROM EMBARQUE e
        INNER JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
        WHERE e.id_satellite = %s
        ORDER BY i.modele
        """,
        (id_satellite,),
        error_message="Erreur lors de la lecture des instruments embarqués",
    )
    if err:
        return err
    return jsonify(rows), 200


# --- Back-office écriture (POST/PATCH/DELETE /api/*) ---


@actions_bp.post("/satellites/<id_satellite>/statut")
@login_required
@role_required("operateur", "admin", error_message=_ERR_STATUT)
def update_satellite_statut(id_satellite):
    data = request.get_json(silent=True) or {}
    statut = (data.get("statut") or "").strip()
    if statut not in _SATELLITE_STATUTS:
        return jsonify(error="Statut invalide"), 400

    rows, err = db_query(
        "SELECT id_satellite FROM SATELLITE WHERE id_satellite = %s",
        (id_satellite,),
        error_message="Erreur lors de la vérification du satellite",
    )
    if err:
        return err
    if not rows:
        return jsonify(error="Satellite introuvable"), 400

    result, err = db_execute(
        "UPDATE SATELLITE SET statut = %s WHERE id_satellite = %s",
        (statut, id_satellite),
        error_message="Erreur lors de la mise à jour du statut",
    )
    if err:
        return err
    if result["rowcount"] == 0:
        return jsonify(error="Satellite introuvable"), 400

    return jsonify(message="Statut du satellite mis à jour."), 200


@actions_bp.post("/fenetres")
@login_required
@role_required("operateur", "admin", error_message=_ERR_FENETRE)
def create_fenetre():
    data = request.get_json(silent=True) or {}
    id_satellite = data.get("id_satellite")
    id_station = data.get("id_station")
    date_heure_debut = (data.get("date_heure_debut") or "").strip()
    duree_secondes = data.get("duree_secondes")
    elevation_max = data.get("elevation_max")

    if id_satellite is None or id_station is None:
        return jsonify(error="Satellite et station requis"), 400
    if not date_heure_debut:
        return jsonify(error="Date et heure de début requises"), 400
    if duree_secondes is None or not (1 <= int(duree_secondes) <= 900):
        return jsonify(error="La durée doit être comprise entre 1 et 900 secondes"), 400
    if elevation_max is None:
        return jsonify(error="Élévation maximale requise"), 400

    statut = (data.get("statut") or "Planifiée").strip()
    if statut != "Planifiée":
        return jsonify(error="Seul le statut « Planifiée » est autorisé à la création"), 400

    result, err = db_execute(
        """
        INSERT INTO FENETRE_COMM
            (id_satellite, code_station, datetime_debut, duree, elevation_max, statut)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (
            id_satellite,
            id_station,
            date_heure_debut,
            int(duree_secondes),
            elevation_max,
            statut,
        ),
        error_message="Erreur lors de la planification de la fenêtre",
    )
    if err:
        return err

    return jsonify(
        message="Fenêtre de communication planifiée.",
        id_fenetre=result["lastrowid"],
    ), 201


@actions_bp.post("/participations")
@login_required
@role_required("responsable", "admin", error_message=_ERR_PARTICIPATION)
def create_participation():
    data = request.get_json(silent=True) or {}
    id_satellite = data.get("id_satellite")
    id_mission = data.get("id_mission")
    role_satellite = (data.get("role_satellite") or "").strip()

    if id_satellite is None or id_mission is None:
        return jsonify(error="Satellite et mission requis"), 400
    if not role_satellite:
        return jsonify(error="Rôle du satellite requis"), 400

    mission_rows, err = db_query(
        "SELECT statut_mission FROM MISSION WHERE id_mission = %s",
        (id_mission,),
        error_message="Erreur lors de la vérification de la mission",
    )
    if err:
        return err
    if not mission_rows:
        return jsonify(error="Mission introuvable"), 400
    if mission_rows[0].get("statut_mission") == "Terminée":
        return jsonify(error="Impossible d'assigner : la mission est terminée."), 400

    existing, err = db_query(
        """
        SELECT 1 AS found
        FROM PARTICIPE
        WHERE id_satellite = %s AND id_mission = %s
        """,
        (id_satellite, id_mission),
        error_message="Erreur lors de la vérification de la participation",
    )
    if err:
        return err
    if existing:
        return jsonify(error="Ce satellite participe déjà à cette mission."), 400

    _, err = db_execute(
        """
        INSERT INTO PARTICIPE (id_satellite, id_mission, role_satellite)
        VALUES (%s, %s, %s)
        """,
        (id_satellite, id_mission, role_satellite),
        error_message="Erreur lors de l'assignation du satellite",
    )
    if err:
        return err

    return jsonify(message="Satellite assigné à la mission."), 201


@actions_bp.post("/satellites/<id_satellite>/desorbiter")
@login_required
@role_required("admin", error_message=_ERR_DESORBITER)
def desorbiter_satellite(id_satellite):
    data = request.get_json(silent=True) or {}
    if not data.get("confirm"):
        return jsonify(
            error="Confirmation requise : envoyez confirm: true pour désorbiter le satellite."
        ), 400

    rows, err = db_query(
        "SELECT statut FROM SATELLITE WHERE id_satellite = %s",
        (id_satellite,),
        error_message="Erreur lors de la vérification du satellite",
    )
    if err:
        return err
    if not rows:
        return jsonify(error="Satellite introuvable"), 400
    if rows[0].get("statut") == "Désorbité":
        return jsonify(error="Ce satellite est déjà désorbité."), 400

    fenetres_annulees = _call_desorbiter_procedure(id_satellite)
    if fenetres_annulees is None:
        result, err = db_execute(
            "UPDATE SATELLITE SET statut = 'Désorbité' WHERE id_satellite = %s",
            (id_satellite,),
            error_message="Erreur lors de la désorbitation",
        )
        if err:
            return err
        if result["rowcount"] == 0:
            return jsonify(error="Satellite introuvable"), 400
        return jsonify(message="Satellite désorbité."), 200

    return jsonify(
        message="Satellite désorbité.",
        fenetres_annulees=fenetres_annulees,
    ), 200


def _call_desorbiter_procedure(id_satellite):
    from mysql.connector import Error

    from app.api.helpers import session_credentials
    from app import db

    user, pwd = session_credentials()
    conn = db.get_connection(user, pwd)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute("CALL desorbiter_satellite(%s, @n)", (id_satellite,))
            while cursor.nextset():
                pass
            cursor.execute("SELECT @n AS operations")
            row = cursor.fetchone()
            conn.commit()
            return int(row["operations"]) if row and row.get("operations") is not None else 0
        except Error as error:
            if error.errno == 1305:
                return None
            raise
        finally:
            cursor.close()
    finally:
        conn.close()


@actions_bp.post("/embarquements")
@login_required
@role_required("operateur", "admin", error_message=_ERR_EMBARQUEMENT)
def create_embarquement():
    data = request.get_json(silent=True) or {}
    id_satellite = data.get("id_satellite")
    ref_instrument = (
        data.get("ref_instrument") or data.get("id_instrument") or ""
    ).strip()
    etat = (data.get("etat_fonctionnement") or "Nominal").strip()

    if id_satellite is None or not ref_instrument:
        return jsonify(error="Satellite et instrument requis"), 400
    if etat not in _INSTRUMENT_ETATS:
        return jsonify(error="État de fonctionnement invalide"), 400

    _, err = db_execute(
        """
        INSERT INTO EMBARQUE (id_satellite, ref_instrument, date_integration, etat_fonctionnement)
        VALUES (%s, %s, CURDATE(), %s)
        """,
        (id_satellite, ref_instrument, etat),
        error_message="Erreur lors de l'embarquement de l'instrument",
    )
    if err:
        return err

    return jsonify(message="Instrument embarqué sur le satellite."), 201


@actions_bp.delete("/embarquements/<id_satellite>/<id_instrument>")
@login_required
@role_required("operateur", "admin", error_message=_ERR_EMBARQUEMENT)
def delete_embarquement(id_satellite, id_instrument):
    result, err = db_execute(
        """
        DELETE FROM EMBARQUE
        WHERE id_satellite = %s AND ref_instrument = %s
        """,
        (id_satellite, id_instrument),
        error_message="Erreur lors du retrait de l'instrument",
    )
    if err:
        return err
    if result["rowcount"] == 0:
        return jsonify(error="Embarquement introuvable"), 400

    return jsonify(message="Instrument retiré du satellite."), 200


@actions_bp.patch("/embarquements/<id_satellite>/<id_instrument>")
@login_required
@role_required("operateur", "admin", error_message=_ERR_EMBARQUEMENT)
def update_embarquement_etat(id_satellite, id_instrument):
    data = request.get_json(silent=True) or {}
    etat = (data.get("etat_fonctionnement") or "").strip()
    if etat not in _INSTRUMENT_ETATS:
        return jsonify(error="État de fonctionnement invalide"), 400

    result, err = db_execute(
        """
        UPDATE EMBARQUE
        SET etat_fonctionnement = %s
        WHERE id_satellite = %s AND ref_instrument = %s
        """,
        (etat, id_satellite, id_instrument),
        error_message="Erreur lors de la mise à jour de l'état",
    )
    if err:
        return err
    if result["rowcount"] == 0:
        return jsonify(error="Embarquement introuvable"), 400

    return jsonify(message="État de l'instrument mis à jour."), 200
