-- =================================================================================
-- Noms : Lugagne Théo / Police Dorian / Boudeville Tom
-- Groupe : 14
-- Date : 10/04/2025
-- SGBD Cible : MySQL
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- 1. Requêtes de base
-- ---------------------------------------------------------------------------------

-- R01 - Niveau 1 : Catalogue des satellites
SELECT s.id_satellite, s.nom_satellite, s.statut, o.type_orbite
FROM SATELLITE s
    JOIN ORBITE o ON s.id_orbite = o.id_orbite
ORDER BY s.statut, s.nom_satellite;

-- R02 - Niveau 1 : Instruments embarqués
SELECT s.nom_satellite, i.ref_instrument, i.type_instrument, i.modele, e.etat_fonctionnement
FROM SATELLITE s
    JOIN EMBARQUE e ON s.id_satellite = e.id_satellite -- n'inclus pas les satellites sans embarquement
    JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument;

-- R03 - Niveau 1 : Historique des communications
SELECT f.datetime_debut, f.duree, s.nom_satellite, st.nom_station, f.statut
FROM FENETRE_COMM f
    JOIN SATELLITE s ON f.id_satellite = s.id_satellite
    JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée'
ORDER BY f.datetime_debut DESC;

-- R04 - Niveau 1 : Satellites par mission
SELECT s.id_satellite, s.nom_satellite, m.nom_mission, p.role_satellite
FROM SATELLITE s
    JOIN PARTICIPE p ON s.id_satellite = p.id_satellite
    JOIN MISSION m ON p.id_mission = m.id_mission
WHERE m.nom_mission LIKE '%Arctic%';

-- R05 - Niveau 1 : Stations disponibles
SELECT nom_station, latitude, longitude, bande_frequence, debit_max
FROM STATION_SOL
WHERE statut NOT IN ('En maintenance', 'Inactive')
ORDER BY debit_max DESC;

-- ---------------------------------------------------------------------------------
-- 2. Requêtes intermédiaires
-- ---------------------------------------------------------------------------------

-- R06 - Niveau 2 : Répartition de la flotte par orbite
SELECT o.type_orbite, o.altitude,
    COUNT(s.id_satellite) AS nb_satellites_total,
    SUM(CASE WHEN s.statut = 'Opérationnel' THEN 1 ELSE 0 END) AS nb_operationnels
FROM ORBITE o
    JOIN SATELLITE s ON o.id_orbite = s.id_orbite
GROUP BY o.id_orbite;

-- R07 - Niveau 2 : Bilan des instruments par satellite
SELECT s.nom_satellite,
    COUNT(e.ref_instrument) AS nb_instruments,
    SUM(CASE WHEN e.etat_fonctionnement = 'Nominal' THEN 1 ELSE 0 END) AS nb_instruments_nominaux,
    SUM(i.consommation) AS consommation_totale_watts
FROM SATELLITE s
    JOIN EMBARQUE e ON s.id_satellite = e.id_satellite
    JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
GROUP BY s.id_satellite
ORDER BY nb_instruments DESC;

-- R08 - Niveau 2 : Volume de données par station
SELECT st.nom_station,
    COUNT(f.id_fenetre) AS nb_fenetres_realisees,
    SUM(NVL(f.volume_donnees, 0)) AS volume_total_Mo,
    AVG(NVL(f.volume_donnees, 0)) AS volume_moyen_Mo
FROM STATION_SOL st
    JOIN FENETRE_COMM f ON st.code_station = f.code_station
WHERE f.statut = 'Réalisée'
GROUP BY st.code_station;

-- R09 - Niveau 2 : Satellites multi-missions
SELECT s.id_satellite, s.nom_satellite, s.statut, COUNT(p.id_mission) AS nb_missions
FROM SATELLITE s
    JOIN PARTICIPE p ON s.id_satellite = p.id_satellite
GROUP BY s.id_satellite, s.nom_satellite, s.statut
HAVING COUNT(*) > 1
ORDER BY nb_missions DESC;

-- R10 - Niveau 2 : Durée moyenne des passages
SELECT o.type_orbite,
    AVG(f.duree) AS duree_moyenne_sec,
    MAX(f.duree) AS duree_max_sec,
    MIN(f.duree) AS duree_min_sec
FROM ORBITE o
    JOIN SATELLITE s ON o.id_orbite = s.id_orbite
    JOIN FENETRE_COMM f ON s.id_satellite = f.id_satellite
WHERE f.statut = 'Réalisée'
GROUP BY o.type_orbite
HAVING COUNT(f.id_fenetre) >= 1; -- Seuil à 1 car petit jeu de données.

-- ---------------------------------------------------------------------------------
-- 3. Requêtes avancées
-- ---------------------------------------------------------------------------------

-- R11 - Niveau 3 : Satellites sans mission (Solution 2 avec NOT EXISTS, plus performant)
SELECT s.id_satellite, s.nom_satellite, s.statut
FROM SATELLITE s
WHERE NOT EXISTS (
    SELECT 1 FROM PARTICIPE p WHERE p.id_satellite = s.id_satellite
);

-- R12 - Niveau 3 : Instruments nécessitant une attention
SELECT s.nom_satellite, s.statut, i.ref_instrument, i.type_instrument, e.etat_fonctionnement,
    CASE WHEN e.etat_fonctionnement = 'Hors service' AND s.statut = 'Opérationnel' THEN 'CRITIQUE'
    ELSE 'RAS' END AS niveau_alerte
FROM INSTRUMENT i
    JOIN EMBARQUE e ON i.ref_instrument = e.ref_instrument
    JOIN SATELLITE s ON e.id_satellite = s.id_satellite
WHERE e.etat_fonctionnement != 'Nominal';

-- R13 - Niveau 3 : Stations sans communication
SELECT st.code_station, st.nom_station, st.statut, st.bande_frequence
FROM STATION_SOL st
    LEFT JOIN FENETRE_COMM f ON st.code_station = f.code_station AND f.statut = 'Réalisée'
WHERE f.id_fenetre IS NULL;
-- EXPLICATION : Une station peut se retrouver dans cette situation si elle est "En maintenance"
-- (d'après RG-G03, il est impossible de créer des fenêtres de communication durant une maintenance),
-- si elle vient d'être construite, ou si aucun satellite compatible n'est passé dans sa zone.

-- R14 - Niveau 3 : Satellites les plus communicants
SELECT s.nom_satellite,
    COUNT(f.id_fenetre) AS nb_fenetres_realisees,
    COUNT(DISTINCT f.code_station) AS nb_stations_differentes
FROM SATELLITE s
    JOIN FENETRE_COMM f ON s.id_satellite = f.id_satellite
WHERE s.statut = 'Opérationnel' AND f.statut = 'Réalisée'
GROUP BY s.id_satellite
HAVING COUNT(DISTINCT f.code_station) >= 2
ORDER BY nb_fenetres_realisees DESC;

-- R15 - Niveau 3 : Analyse croisée missions / orbites
SELECT m.id_mission, m.nom_mission,
    COUNT(DISTINCT s.id_satellite) AS nb_satellites_participants,
    GROUP_CONCAT(DISTINCT o.type_orbite SEPARATOR ', ') AS types_orbites_representes
FROM MISSION m
    JOIN PARTICIPE p ON m.id_mission = p.id_mission
    JOIN SATELLITE s ON p.id_satellite = s.id_satellite
    JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE m.statut_mission = 'Active'
GROUP BY m.id_mission;

-- ---------------------------------------------------------------------------------
-- 4. Vues métiers
-- ---------------------------------------------------------------------------------

-- V01 - VUE_SATELLITES_OPERATIONNELS
CREATE OR REPLACE VIEW VUE_SATELLITES_OPERATIONNELS AS
SELECT s.id_satellite, s.nom_satellite, s.format_cubesat, s.date_lancement, o.type_orbite, o.altitude, s.capacite_batterie
FROM SATELLITE s
    JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE s.statut = 'Opérationnel';

-- V01 - Question (a)
SELECT * FROM VUE_SATELLITES_OPERATIONNELS WHERE type_orbite = 'SSO';
-- V01 - Question (b)
SELECT AVG(DATEDIFF(CURRENT_DATE, date_lancement)) AS age_moyen_jours FROM VUE_SATELLITES_OPERATIONNELS;


-- V02 - VUE_BILAN_COMMUNICATIONS
CREATE OR REPLACE VIEW VUE_BILAN_COMMUNICATIONS AS
SELECT s.id_satellite, s.nom_satellite,
    COUNT(f.id_fenetre) AS nb_fenetres,
    SUM(f.volume_donnees) AS volume_total,
    AVG(f.volume_donnees) AS volume_moyen,
    MAX(f.datetime_debut) AS date_derniere_com,
    COUNT(DISTINCT f.code_station) AS nb_stations
FROM SATELLITE s
    LEFT JOIN FENETRE_COMM f ON s.id_satellite = f.id_satellite AND f.statut = 'Réalisée'
GROUP BY s.id_satellite
HAVING COUNT(f.id_fenetre) > 0; -- Seuil à 0 pour exclure les satellites sans aucune communication réalisée.

-- V02 - Question (a)
SELECT * FROM VUE_BILAN_COMMUNICATIONS ORDER BY volume_total DESC LIMIT 1;
-- V02 - Question (b)
SELECT * FROM SATELLITE s
WHERE NOT EXISTS(
    SELECT 1 FROM VUE_BILAN_COMMUNICATIONS v WHERE v.id_satellite = s.id_satellite
) AND s.statut = 'Opérationnel';


-- V03 - VUE_TABLEAU_DE_BORD_MISSIONS
CREATE OR REPLACE VIEW VUE_TABLEAU_DE_BORD_MISSIONS AS
SELECT m.id_mission, m.nom_mission, m.zone_geo_cible, m.date_debut,
    COUNT(p.id_satellite) AS nb_satellites,
    SUM(CASE WHEN s.statut = 'Opérationnel' THEN 1 ELSE 0 END) AS nb_sat_operationnels
FROM MISSION m
    JOIN PARTICIPE p ON m.id_mission = p.id_mission
    JOIN SATELLITE s ON p.id_satellite = s.id_satellite
WHERE m.statut_mission = 'Active'
GROUP BY m.id_mission;

-- V03 - Question (a)
SELECT * FROM VUE_TABLEAU_DE_BORD_MISSIONS WHERE nb_satellites >= 2;
-- V03 - Question (b)
SELECT * FROM VUE_TABLEAU_DE_BORD_MISSIONS WHERE nb_satellites = nb_sat_operationnels;


-- V04 - VUE_ALERTES_INSTRUMENTS
CREATE OR REPLACE VIEW VUE_ALERTES_INSTRUMENTS AS
SELECT s.nom_satellite, s.statut AS statut_satellite, i.ref_instrument, i.type_instrument, e.etat_fonctionnement,
    CASE WHEN s.statut = 'Opérationnel' AND e.etat_fonctionnement = 'Hors service' THEN 'CRITIQUE'
    ELSE 'SURVEILLANCE' END AS priorite
FROM SATELLITE s
    JOIN EMBARQUE e ON s.id_satellite = e.id_satellite
    JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
WHERE e.etat_fonctionnement NOT IN ('Nominal');

-- V04 - Question (a)
SELECT * FROM VUE_ALERTES_INSTRUMENTS WHERE priorite = 'CRITIQUE';
-- V04 - Question (b)
SELECT type_instrument, COUNT(*) as nb_alertes FROM VUE_ALERTES_INSTRUMENTS GROUP BY type_instrument;