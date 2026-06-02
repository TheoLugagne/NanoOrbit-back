-- =================================================================================
-- Noms : Lugagne Théo / Police Dorian / Boudeville Tom
-- Groupe : 14
-- Date : 25/03/2025
-- SGBD Cible : MySQL
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- 3.1 Création du schéma
-- ---------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS nanoOrbit_db CHARACTER SET utf8mb4;
USE nanoOrbit_db;

-- ---------------------------------------------------------------------------------
-- REPONSES AUX QUESTIONS DE REFLEXION (3.4)
-- ---------------------------------------------------------------------------------
-- Justification de l'ordre de création (3.3) :
-- Les tables sans clés étrangères doivent être créées en premier (ORBITE,
-- INSTRUMENT, MISSION, STATION_SOL). Ensuite, on crée SATELLITE qui dépend d'ORBITE.
-- Enfin, on crée les tables d'associations (EMBARQUE, PARTICIPE,
-- FENETRE_COMM).
--
-- Q1: Pourquoi ne peut-on pas créer SATELLITE avant ORBITE ?
-- Réponse : SATELLITE possède une clé étrangère (id_orbite) qui référence la table ORBITE.
-- Créer SATELLITE en premier provoquerait une erreur.
--
-- Q2: Le champ format_cubesat dans SATELLITE : quel type SQL choisissez-vous ?
-- Réponse : Le type ENUM.
--
-- Q3: Comment implémentez-vous la contrainte RG-I03 ?
-- Réponse : On ne peut pas l'implémenter, ce n'est pas exprimable en DDL simple.
--
-- Q4: La règle RG-S06 (satellite désorbité) peut-elle être vérifiée au niveau DDL ?
-- Réponse : Non, le DDL (CHECK, FK) ne permet pas de bloquer des insertions dans une autre
-- table en fonction de l'état d'une ligne parente. La solution est de créer un TRIGGER BEFORE INSERT
-- sur FENETRE_COMM et PARTICIPE pour lever une erreur si le statut du satellite est 'Désorbité'.
-- ---------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------
-- 3.2 DDL
-- ---------------------------------------------------------------------------------

CREATE TABLE ORBITE(
                       id_orbite INT AUTO_INCREMENT,
                       type_orbite ENUM('LEO', 'MEO', 'SSO', 'GEO') NOT NULL,
                       altitude INT NOT NULL,
                       inclinaison DECIMAL(5,2) NOT NULL,
                       periode_orbitale DECIMAL(5,2) NOT NULL,
                       excentricite DECIMAL(6,6) NOT NULL,
                       zone_couverture VARCHAR(100) NOT NULL,
                       PRIMARY KEY (id_orbite),
                       UNIQUE (altitude, inclinaison) -- E3 : Contrainte UNIQUE
)ENGINE=InnoDB;

CREATE TABLE INSTRUMENT(
                           ref_instrument VARCHAR(50),
                           type_instrument VARCHAR(50) NOT NULL,
                           modele VARCHAR(100) NOT NULL,
                           resolution DECIMAL(5,2) DEFAULT NULL, -- Exception à la règle E1 : NULL par default.
                           consommation DECIMAL(4,1) NOT NULL,
                           masse DECIMAL(4,2) NOT NULL,
                           PRIMARY KEY (ref_instrument)
)ENGINE=InnoDB;

CREATE TABLE MISSION(
                        id_mission VARCHAR(50),
                        nom_mission VARCHAR(100) NOT NULL,
                        objectif VARCHAR(500) NOT NULL, -- Rendue NOT NULL (E1) même si absente du tableau 4.6
                        zone_geo_cible VARCHAR(100) NOT NULL,
                        date_debut DATE NOT NULL,
                        date_fin DATE, -- E1 : Peut être NULL
                        statut_mission ENUM('Active', 'Terminée', 'Suspendue') NOT NULL,
                        PRIMARY KEY (id_mission)
)ENGINE=InnoDB;

CREATE TABLE STATION_SOL (
                             code_station VARCHAR(50),
                             nom_station VARCHAR(100) NOT NULL,
                             latitude DECIMAL(7,4) NOT NULL,
                             longitude DECIMAL(7,4) NOT NULL,
                             diametre_antenne DECIMAL(4,1) NOT NULL,
                             bande_frequence ENUM('UHF', 'S-Band', 'X-Band', 'Ka-Band') NOT NULL, -- E2
                             debit_max DECIMAL(6,1) NOT NULL,
                             statut ENUM('Active', 'Maintenance', 'Inactive') NOT NULL, -- E2
                             PRIMARY KEY (code_station)
)ENGINE=InnoDB;

CREATE TABLE SATELLITE (
                           id_satellite VARCHAR(50),
                           nom_satellite VARCHAR(100) NOT NULL,
                           date_lancement DATE NOT NULL,
                           masse DECIMAL(5,1) NOT NULL,
                           format_cubesat ENUM('1U', '3U', '6U', '12U') NOT NULL,
                           statut ENUM('Opérationnel', 'En veille', 'Défaillant', 'Désorbité') NOT NULL, -- E2
                           duree_vie_prevue INT NOT NULL,
                           capacite_batterie DECIMAL(5,1) NOT NULL,
                           id_orbite INT NOT NULL,
                           PRIMARY KEY (id_satellite),
                           FOREIGN KEY (id_orbite) REFERENCES ORBITE(id_orbite) ON DELETE RESTRICT -- E5
)ENGINE=InnoDB;

CREATE TABLE EMBARQUE (
                          id_satellite VARCHAR(50) NOT NULL,
                          ref_instrument VARCHAR(50) NOT NULL,
                          date_integration DATE NOT NULL,
                          etat_fonctionnement ENUM('Nominal', 'Dégradé', 'Hors service') NOT NULL, -- E2
                          PRIMARY KEY (id_satellite, ref_instrument), -- E6 : PK Composite
                          FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
                          FOREIGN KEY (ref_instrument) REFERENCES INSTRUMENT(ref_instrument) ON DELETE RESTRICT
)ENGINE=InnoDB;

CREATE TABLE PARTICIPE (
                           id_satellite VARCHAR(50) NOT NULL,
                           id_mission VARCHAR(50) NOT NULL,
                           role_satellite VARCHAR(50) NOT NULL,
                           PRIMARY KEY (id_satellite, id_mission), -- E6 : PK Composite
                           FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
                           FOREIGN KEY (id_mission) REFERENCES MISSION(id_mission) ON DELETE RESTRICT
)ENGINE=InnoDB;

CREATE TABLE FENETRE_COMM (
                              id_fenetre INT AUTO_INCREMENT,
                              datetime_debut DATETIME NOT NULL,
                              duree INT NOT NULL CHECK (duree >= 1 AND duree <= 900), -- E4 : Contrainte CHECK
                              elevation_max DECIMAL(4,1) NOT NULL,
                              volume_donnees DECIMAL(6,1), -- E1 : Peut être NULL
                              statut ENUM('Planifiée', 'En cours', 'Réalisée', 'Échouée') NOT NULL, -- E2
                              id_satellite VARCHAR(50) NOT NULL,
                              code_station VARCHAR(50) NOT NULL,
                              PRIMARY KEY (id_fenetre),
                              FOREIGN KEY (id_satellite) REFERENCES SATELLITE(id_satellite) ON DELETE RESTRICT,
                              FOREIGN KEY (code_station) REFERENCES STATION_SOL(code_station) ON DELETE RESTRICT
)ENGINE=InnoDB;


-- ---------------------------------------------------------------------------------
-- 4. DML
-- ---------------------------------------------------------------------------------

INSERT INTO ORBITE (id_orbite, type_orbite, altitude, inclinaison, periode_orbitale, excentricite, zone_couverture) VALUES
                                                                                                                        (1, 'SSO', 550, 97.40, 95.70, 0.001000, 'Zones polaires / Arctique'),
                                                                                                                        (2, 'LEO', 400, 51.60, 92.65, 0.000300, 'Ceinture tropicale'),
                                                                                                                        (3, 'SSO', 600, 97.80, 96.70, 0.000800, 'Amazonie / Afrique centrale');

INSERT INTO INSTRUMENT (ref_instrument, type_instrument, modele, resolution, consommation, masse) VALUES
                                                                                                      ('CAM-HR-01', 'Caméra optique', 'PocketQube-CAM v2', 5.0, 3.2, 0.45),
                                                                                                      ('IR-MID-01', 'Capteur IR', 'ThermoSat IRv3', 30.0, 2.8, 0.38),
                                                                                                      ('AIS-01', 'Capteur AIS', 'MarineTrack-Nano', NULL, 1.5, 0.22),
                                                                                                      ('CAM-HR-02', 'Caméra optique', 'PocketQube-CAM v3', 3.5, 4.0, 0.50);

-- NB: L'objectif étant manquant dans les données 4.6 de l'énoncé, une valeur par défaut a été ajoutée pour respecter le NOT NULL.
INSERT INTO MISSION (id_mission, nom_mission, objectif, zone_geo_cible, date_debut, date_fin, statut_mission) VALUES
                                                                                                                  ('MSN-AMA-2023', 'ForestWatch Amazonia', 'Surveillance des forêts', 'Amérique du Sud (-5N, 50O)', '2023-04-01', '2025-03-31', 'Active'),
                                                                                                                  ('MSN-ARC-2023', 'ArcticIce Monitor', 'Surveillance des glaces', 'Arctique (>70N)', '2023-04-01', NULL, 'Active'),
                                                                                                                  ('MSN-AIS-2024', 'SeaTrack Global', 'Suivi du trafic maritime', 'Océans mondiaux', '2024-02-01', '2024-12-31', 'Terminée');

INSERT INTO STATION_SOL (code_station, nom_station, latitude, longitude, diametre_antenne, bande_frequence, debit_max, statut) VALUES
                                                                                                                                   ('GS-TLS-01', 'Toulouse-CNES', 43.6050, 1.4440, 3.7, 'S-Band', 100.0, 'Active'),
                                                                                                                                   ('GS-KIR-01', 'Kiruna-SSC', 67.8560, 20.2280, 5.4, 'X-Band', 300.0, 'Active'),
                                                                                                                                   ('GS-SGP-01', 'SingaporeSATEC', 1.3521, 103.8198, 2.8, 'S-Band', 80.0, 'Maintenance');

INSERT INTO SATELLITE (id_satellite, nom_satellite, date_lancement, masse, format_cubesat, statut, duree_vie_prevue, capacite_batterie, id_orbite) VALUES
                                                                                                                                                       ('SAT-001', 'NanoOrbitAlpha', '2023-03-12', 4.5, '3U', 'Opérationnel', 36, 60.0, 1),
                                                                                                                                                       ('SAT-002', 'NanoOrbitBeta', '2023-03-12', 4.5, '3U', 'Opérationnel', 36, 60.0, 1),
                                                                                                                                                       ('SAT-003', 'NanoOrbitGamma', '2023-09-05', 8.2, '6U', 'En veille', 48, 110.0, 2),
                                                                                                                                                       ('SAT-004', 'NanoOrbitDelta', '2024-01-20', 4.8, '3U', 'Opérationnel', 36, 65.0, 3),
                                                                                                                                                       ('SAT-005', 'NanoOrbitEpsilon', '2022-06-15', 4.5, '3U', 'Désorbité', 24, 55.0, 1);

-- Question BONUS 4.4: Est-ce conforme à RG-I03 ?
-- Réponse: Oui, car "AIS-01" est une référence de modèle et non un identifiant
-- d'objet unique. Deux satellites peuvent embarquer la même référence.
INSERT INTO EMBARQUE (id_satellite, ref_instrument, date_integration, etat_fonctionnement) VALUES
                                                                                               ('SAT-001', 'CAM-HR-01', '2023-02-01', 'Nominal'),
                                                                                               ('SAT-001', 'IR-MID-01', '2023-02-01', 'Dégradé'),
                                                                                               ('SAT-002', 'CAM-HR-01', '2023-02-10', 'Nominal'),
                                                                                               ('SAT-002', 'AIS-01', '2023-02-10', 'Nominal'),
                                                                                               ('SAT-003', 'IR-MID-01', '2023-08-01', 'Nominal'),
                                                                                               ('SAT-004', 'CAM-HR-02', '2024-01-05', 'Nominal'),
                                                                                               ('SAT-004', 'AIS-01', '2024-01-05', 'Nominal');

INSERT INTO PARTICIPE (id_satellite, id_mission, role_satellite) VALUES
                                                                     ('SAT-001', 'MSN-AMA-2023', 'Satellite primaire'),
                                                                     ('SAT-002', 'MSN-AMA-2023', 'Satellite de backup'),
                                                                     ('SAT-003', 'MSN-ARC-2023', 'Satellite primaire'),
                                                                     ('SAT-001', 'MSN-ARC-2023', 'Satellite de calibration'),
                                                                     ('SAT-004', 'MSN-AIS-2024', 'Satellite primaire'),
                                                                     ('SAT-002', 'MSN-AIS-2024', 'Satellite de backup');

INSERT INTO FENETRE_COMM (id_fenetre, datetime_debut, duree, elevation_max, volume_donnees, statut, id_satellite, code_station) VALUES
                                                                                                                                    (1, '2024-03-15 14:32:00', 420, 68.4, 1250.0, 'Réalisée', 'SAT-001', 'GS-TLS-01'),
                                                                                                                                    (2, '2024-03-15 16:08:00', 380, 52.1, 890.0, 'Réalisée', 'SAT-002', 'GS-KIR-01'),
                                                                                                                                    (3, '2024-03-16 08:15:00', 510, 74.2, NULL, 'Planifiée', 'SAT-003', 'GS-KIR-01'),
                                                                                                                                    (4, '2024-03-16 09:00:00', 300, 45.0, NULL, 'Planifiée', 'SAT-004', 'GS-TLS-01'),
                                                                                                                                    (5, '2024-03-15 22:44:00', 280, 38.7, 620.0, 'Réalisée', 'SAT-001', 'GS-KIR-01');

-- ---------------------------------------------------------------------------------
-- 5. Vérifications attendues (Requêtes SELECT de contrôle)
-- ---------------------------------------------------------------------------------

-- V1: Listez tous les satellites opérationnels avec le nom de leur orbite.
/* Résultat attendu : SAT-001 (SSO), SAT-002 (SSO), SAT-004 (SSO) */
SELECT s.nom_satellite, o.type_orbite
FROM SATELLITE s
         JOIN ORBITE o ON s.id_orbite = o.id_orbite
WHERE s.statut = 'Opérationnel';

-- V2: Affichez les instruments embarqués sur SAT-001 avec leur état de fonctionnement.
/* Résultat attendu : CAM-HR-01 (Nominal), IR-MID-01 (Dégradé) */
SELECT i.modele, e.etat_fonctionnement
FROM EMBARQUE e
         JOIN INSTRUMENT i ON e.ref_instrument = i.ref_instrument
WHERE e.id_satellite = 'SAT-001';

-- V3: Listez les fenêtres de communication réalisées avec le nom du satellite et de la station.
/* Résultat attendu : F1 (NanoOrbitAlpha, Toulouse), F2 (NanoOrbitBeta, Kiruna), F5 (NanoOrbitAlpha, Kiruna) */
SELECT f.id_fenetre, s.nom_satellite, st.nom_station
FROM FENETRE_COMM f
         JOIN SATELLITE s ON f.id_satellite = s.id_satellite
         JOIN STATION_SOL st ON f.code_station = st.code_station
WHERE f.statut = 'Réalisée';

-- V4: Affichez les satellites participant à la mission MSN-ARC-2023 avec leur rôle.
/* Résultat attendu : NanoOrbitGamma (primaire), NanoOrbitAlpha (calibration) */
SELECT s.nom_satellite, p.role_satellite
FROM PARTICIPE p
         JOIN SATELLITE s ON p.id_satellite = s.id_satellite
WHERE p.id_mission = 'MSN-ARC-2023';

-- V5: Comptez le nombre d'instruments embarqués par satellite (ORDER BY DESC).
/* Résultat attendu : SAT-001 (2), SAT-002 (2), SAT-004 (2), SAT-003 (1) */
SELECT id_satellite, COUNT(ref_instrument) AS nb_instruments
FROM EMBARQUE
GROUP BY id_satellite
ORDER BY nb_instruments DESC;