-- =================================================================================
-- Noms : Lugagne Théo / Police Dorian / Boudeville Tom
-- Groupe : 14
-- Date : 05/05/2026
-- SGBD Cible : MySQL (version déployée — AlwaysData)
-- Base : tlugagne_tp
-- Utilisateurs : tlugagne_analyst / tlugagne_operateur / tlugagne_responsable / tlugagne
-- =================================================================================

USE tlugagne_tp;

-- ---------------------------------------------------------------------------------
-- EXERCICE 2 — Comptes (gérés côté hébergeur ; pas de CREATE USER ici)
-- ---------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------
-- EXERCICE 3 — Attribution des droits
-- ---------------------------------------------------------------------------------

-- 1/ Droits de l'analyste données
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_analyst'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_analyst'@'%';

-- 2/ Droits de l'opérateur satellite
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_operateur'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_operateur'@'%';
GRANT UPDATE (statut) ON tlugagne_tp.SATELLITE TO 'tlugagne_operateur'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.FENETRE_COMM TO 'tlugagne_operateur'@'%';

-- 3/ Droits du responsable missions
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_responsable'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_responsable'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.MISSION TO 'tlugagne_responsable'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.PARTICIPE TO 'tlugagne_responsable'@'%';

-- 4/ Droits de l'administrateur technique
GRANT SELECT, INSERT, UPDATE, DELETE ON tlugagne_tp.* TO 'tlugagne'@'%';
GRANT CREATE VIEW ON tlugagne_tp.* TO 'tlugagne'@'%';

-- ---------------------------------------------------------------------------------
-- EXERCICE 4 — Révocations
-- ---------------------------------------------------------------------------------

-- 1/ Scénario : l'opérateur a fait une erreur critique en modifiant un satellite
REVOKE UPDATE (statut) ON tlugagne_tp.SATELLITE FROM 'tlugagne_operateur'@'%';

-- 2/ Scénario : l'analyste quitte l'entreprise
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_analyst'@'%';

-- ---------------------------------------------------------------------------------
-- EXERCICE 5 — Vues publiques et accès restreint pour l'analyste
-- ---------------------------------------------------------------------------------

-- 1/ Vue VUE_SATELLITES_PUBLIQUE
CREATE OR REPLACE VIEW VUE_SATELLITES_PUBLIQUE AS
SELECT s.id_satellite, s.nom_satellite, s.format_cubesat, s.statut, o.type_orbite
FROM SATELLITE s
         JOIN ORBITE o ON s.id_orbite = o.id_orbite;

-- 2/ Droit de lecture sur la vue uniquement
GRANT SELECT ON tlugagne_tp.VUE_SATELLITES_PUBLIQUE TO 'tlugagne_analyst'@'%';

-- 3/ Vue VUE_MISSIONS_PUBLIQUE
CREATE OR REPLACE VIEW VUE_MISSIONS_PUBLIQUE AS
SELECT m.id_mission, m.nom_mission, m.statut_mission, COUNT(p.id_satellite) AS nb_satellites
FROM MISSION m
         LEFT JOIN PARTICIPE p ON m.id_mission = p.id_mission
WHERE m.statut_mission = 'Active'
GROUP BY m.id_mission, m.nom_mission, m.statut_mission;

GRANT SELECT ON tlugagne_tp.VUE_MISSIONS_PUBLIQUE TO 'tlugagne_analyst'@'%';

-- ---------------------------------------------------------------------------------
-- EXERCICE 6 — MISSION 1 : Réinitialisation des droits
-- ---------------------------------------------------------------------------------

-- Opérateur satellite
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_operateur'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_operateur'@'%';
GRANT UPDATE (statut) ON tlugagne_tp.SATELLITE TO 'tlugagne_operateur'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.FENETRE_COMM TO 'tlugagne_operateur'@'%';

-- Analyste données
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_analyst'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_analyst'@'%';

-- Responsable missions
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_responsable'@'%';
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_responsable'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.MISSION TO 'tlugagne_responsable'@'%';
GRANT INSERT, UPDATE ON tlugagne_tp.PARTICIPE TO 'tlugagne_responsable'@'%';

-- Administrateur technique (non modifiable sur le serveur)
# REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne'@'%';
# GRANT SELECT, INSERT, UPDATE, DELETE ON tlugagne_tp.* TO 'tlugagne'@'%';
# GRANT CREATE VIEW ON tlugagne_tp.* TO 'tlugagne'@'%';

-- ---------------------------------------------------------------------------------
-- EXERCICE 6 — MISSION 2
-- ---------------------------------------------------------------------------------

-- 1/ Révocation du droit DELETE sur FENETRE_COMM pour l'opérateur
GRANT DELETE ON tlugagne_tp.FENETRE_COMM TO 'tlugagne_operateur'@'%';
REVOKE DELETE ON tlugagne_tp.FENETRE_COMM FROM 'tlugagne_operateur'@'%';

-- 2/ Compte stagiaire (création gérée côté hébergeur ; expiration à configurer sur le panel)
-- 3/ Accès en lecture seule sur les vues métier
REVOKE INSERT, UPDATE, DELETE ON tlugagne_tp.* FROM 'tlugagne_stagiaire'@'%';
GRANT SELECT ON tlugagne_tp.VUE_SATELLITES_OPERATIONNELS TO 'tlugagne_stagiaire'@'%';
GRANT SELECT ON tlugagne_tp.VUE_BILAN_COMMUNICATIONS TO 'tlugagne_stagiaire'@'%';

-- ---------------------------------------------------------------------------------
-- EXERCICE 6 — MISSION 3
-- ---------------------------------------------------------------------------------

-- 1/ Ingénieur DevOps (compte géré côté hébergeur)
GRANT SELECT ON tlugagne_tp.* TO 'tlugagne_devops'@'%';
GRANT CREATE VIEW, DROP ON tlugagne_tp.* TO 'tlugagne_devops'@'%';

-- 2/ Révocation des droits d'écriture sur PARTICIPE pour le responsable missions
REVOKE INSERT, UPDATE ON tlugagne_tp.PARTICIPE FROM 'tlugagne_responsable'@'%';

-- 3/ Délégation du droit SELECT pour l'administrateur technique
-- GRANT SELECT ON tlugagne_tp.* TO 'tlugagne'@'%' WITH GRANT OPTION;
