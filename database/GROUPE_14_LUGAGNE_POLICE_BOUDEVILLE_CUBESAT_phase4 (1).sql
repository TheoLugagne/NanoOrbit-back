-- =================================================================================
-- Noms : Lugagne Théo / Police Dorian / Boudeville Tom
-- Groupe : 14
-- Date : 05/05/2026
-- SGBD Cible : MySQL
-- =================================================================================

use nanoOrbit_db;

--EXERCICE 2

--1/
-- Création du compte pour l'opérateur satellite
CREATE USER IF NOT EXISTS 'operateur_sat'@'localhost' IDENTIFIED BY 'OpSat_Pwd123!'; 

-- Création du compte pour l'analyste données
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' IDENTIFIED BY 'AnData_Pwd123!'; 

-- Création du compte pour le responsable missions
CREATE USER IF NOT EXISTS 'resp_mission'@'localhost' IDENTIFIED BY 'RespMiss_Pwd123!'; 

-- Création du compte pour l'administrateur technique
CREATE USER IF NOT EXISTS 'admin_nano'@'localhost' IDENTIFIED BY 'AdminNano_Pwd123!'; 


--2/ Vérification de la création des utilisateurs 
SELECT user, host FROM mysql.user; 
-- Il y a 8 instances dans la base, étant connecter actuellement en tant que root, on voit les 4 nouveaux utilisateurs créés et 4 autres déjà existants de mysql.


-- EXERCICE 3

-- 1/ Droits de l'analyste données
GRANT SELECT ON nanoOrbit_db.* TO 'analyste_data'@'localhost'; 
SHOW GRANTS FOR 'analyste_data'@'localhost'; 


-- 2/ Droits de l'opérateur satellite 
GRANT SELECT ON nanoOrbit_db.* TO 'operateur_sat'@'localhost'; 
GRANT UPDATE (statut) ON nanoOrbit_db.SATELLITE TO 'operateur_sat'@'localhost'; 
GRANT INSERT, UPDATE ON nanoOrbit_db.FENETRE_COMM TO 'operateur_sat'@'localhost'; 
SHOW GRANTS FOR 'operateur_sat'@'localhost'; 


-- 3/ Droits du responsable missions 
GRANT SELECT ON nanoOrbit_db.* TO 'resp_mission'@'localhost'; 
GRANT INSERT, UPDATE ON nanoOrbit_db.MISSION TO 'resp_mission'@'localhost'; 
GRANT INSERT, UPDATE ON nanoOrbit_db.PARTICIPE TO 'resp_mission'@'localhost'; 
SHOW GRANTS FOR 'resp_mission'@'localhost'; 

-- 4/ Droits de l'administrateur technique 
GRANT SELECT, INSERT, UPDATE, DELETE ON nanoOrbit_db.* TO 'admin_nano'@'localhost'; 
GRANT CREATE VIEW ON nanoOrbit_db.* TO 'admin_nano'@'localhost'; 
SHOW GRANTS FOR 'admin_nano'@'localhost'; 


-- EXERCICE 4

-- 1/ Scénario l'opérateur_sat a fait une erreur critique en modifiant un satellite
REVOKE UPDATE (statut) ON nanoOrbit_db.SATELLITE FROM 'operateur_sat'@'localhost'; 
SHOW GRANTS FOR 'operateur_sat'@'localhost';


-- 2/ Scénario l'analyste_data quitte l'entreprise
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'analyste_data'@'localhost'; 
DROP USER 'analyste_data'@'localhost'; 
SELECT user, host FROM mysql.user; 


-- 3/ Réflexion : différence entre REVOKE et DROP
-- REVOKE retire les privilèges d'un utilisateur, mais l'utilisateur lui-même existe toujours dans la base de données.
-- DROP supprime complètement l'utilisateur de la base de données, y compris tous les privilèges associés. Après un DROP, l'utilisateur n'existe donc plus et ne peut plus se connecter à la base de données.


-- EXERCICE 5
-- on recréé l'utilisateur pour pouvoir créer la vue
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' IDENTIFIED BY 'AnData_Pwd123!'; 


-- 1/  Créez une vue VUE_SATELLITES_PUBLIQUE
CREATE OR REPLACE VIEW VUE_SATELLITES_PUBLIQUE AS 
SELECT s.id_satellite, s.nom_satellite, s.format_cubesat, s.statut, o.type_orbite 
FROM SATELLITE s 
JOIN ORBITE o ON s.id_orbite = o.id_orbite; 


-- 2/ Accord du droit de lecture sur la vue uniquement 
GRANT SELECT ON nanoOrbit_db.VUE_SATELLITES_PUBLIQUE TO 'analyste_data'@'localhost'; 
-- L'utilisateur analyste_data a reçu le droit SELECT sur la vue, mais aucun droit sur les tables sources sous-jacentes.  
-- Lors de l'interrogation de la vue, MySQL vérifie les droits du créateur de la vue et non ceux de l'utilisateur qui l'interroge. L'accès direct à la table source est refusé, mais l'accès à la vue et aux données qu'elle donne est autorisé( a condition d'avoir les droits select), ce qui valide le pattern de restriction d'accès.


-- 3/  Créez une deuxième vue VUE_MISSIONS_PUBLIQUE
CREATE OR REPLACE VIEW VUE_MISSIONS_PUBLIQUE AS
SELECT m.id_mission, m.nom_mission, m.statut_mission, COUNT(p.id_satellite) AS nb_satellites
FROM MISSION m
LEFT JOIN PARTICIPE p ON m.id_mission = p.id_mission
WHERE m.statut_mission = 'Active'
GROUP BY m.id_mission, m.nom_mission, m.statut_mission;

GRANT SELECT ON nanoOrbit_db.VUE_MISSIONS_PUBLIQUE TO 'analyste_data'@'localhost';
-- Grâce à la vue VUE_MISSIONS_PUBLIQUE, l'utilisateur analyste_data peut consulter la liste des missions actives et obtient également le nombre total de satellites pour chaque mission. Cependant, il ne peut pas obtenir les noms ou les caractéristiques des satellites individuels, car la vue fait des aggrégations de ces données sans les exposer.


-- EXERCICE 6

-- MISSION 1 

-- 1. Création des utilisateurs

-- L'opérateur satellite
DROP USER if EXISTS'operateur_sat'@'localhost'; 
CREATE USER IF NOT EXISTS 'operateur_sat'@'localhost' IDENTIFIED BY 'OpSat_Pwd123!';


-- L'analyste de données
DROP USER if EXISTS'analyste_data'@'localhost'; 
CREATE USER IF NOT EXISTS 'analyste_data'@'localhost' IDENTIFIED BY 'AnData_Pwd123!';


-- Le responsable missions
DROP USER if EXISTS'resp_mission'@'localhost'; 
CREATE USER IF NOT EXISTS 'resp_mission'@'localhost' IDENTIFIED BY 'RespMiss_Pwd123!';


-- L'administrateur technique
DROP USER if EXISTS'admin_nano'@'localhost';
CREATE USER IF NOT EXISTS 'admin_nano'@'localhost' IDENTIFIED BY 'AdminNano_Pwd123!';


-- 2. Attribution des droits

-- Opérateur satellite
-- Choix : On lui donne la lecture sur toute la base. Pour l'écriture, on restreint à la modification du statut du satellite et à la gestion des fenêtres de communication.
GRANT SELECT ON nanoOrbit_db.* TO 'operateur_sat'@'localhost';
GRANT UPDATE (statut) ON nanoOrbit_db.SATELLITE TO 'operateur_sat'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.FENETRE_COMM TO 'operateur_sat'@'localhost';
SHOW GRANTS FOR 'operateur_sat'@'localhost';


-- Analyste données
-- Choix : Ce profil ne fait que de l'exploitation donc il reçoit  uniquement le droit global de lecture sur toute la base.
GRANT SELECT ON nanoOrbit_db.* TO 'analyste_data'@'localhost';
SHOW GRANTS FOR 'analyste_data'@'localhost';


-- Responsable missions
-- Choix : Droit de lecture global pour consulter l'état de la constellation et les droits d'écriture ( insert et update ) sont actifs juste aux tables MISSION et PARTICIPE.
GRANT SELECT ON nanoOrbit_db.* TO 'resp_mission'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.MISSION TO 'resp_mission'@'localhost';
GRANT INSERT, UPDATE ON nanoOrbit_db.PARTICIPE TO 'resp_mission'@'localhost';
SHOW GRANTS FOR 'resp_mission'@'localhost';


-- Administrateur technique
-- Choix : On accorde tous les droits de manipulation de données sur toutes les tables. On ajoute le droit de créer des vues. L'absence de privilège all ou drop l'empêche de détruire la structure de la base ou de gérer les utilisateurs.
GRANT SELECT, INSERT, UPDATE, DELETE ON nanoOrbit_db.* TO 'admin_nano'@'localhost';
GRANT CREATE VIEW ON nanoOrbit_db.* TO 'admin_nano'@'localhost';
SHOW GRANTS FOR 'admin_nano'@'localhost';


-- MISSION 2

-- on rajoute le grant delete pour l'exercice car il ne l'est pas par defaut quand les autres exercice (car il n'y a pas le droit), on ne la donc pas rajouter avant.
GRANT DELETE ON nanoOrbit_db.FENETRE_COMM TO 'operateur_sat'@'localhost';


-- 1/ Révocation du droit DELETE sur FENETRE_COM pour l'opérateur_sat
REVOKE DELETE ON nanoOrbit_db.FENETRE_COMM FROM 'operateur_sat'@'localhost';


-- 2/ Création du compte stagiaire avec expiration automatique dans 14 jours
CREATE USER IF NOT EXISTS 'stagiaire_obs'@'localhost' 
IDENTIFIED BY 'Stagiaire_Pwd123!' 
PASSWORD EXPIRE INTERVAL 14 DAY;


-- 3/ Accès en lecture seule sur les vues métier spécifiées
GRANT SELECT ON nanoOrbit_db.VUE_SATELLITES_OPERATIONNELS TO 'stagiaire_obs'@'localhost';
GRANT SELECT ON nanoOrbit_db.VUE_BILAN_COMMUNICATIONS TO 'stagiaire_obs'@'localhost';


-- 4/ Vérification des droits
SHOW GRANTS FOR 'operateur_sat'@'localhost';
SHOW GRANTS FOR 'stagiaire_obs'@'localhost';


-- MISSION 3
-- 1. Création de l'ingénieur DevOps
CREATE USER IF NOT EXISTS 'devops_nano'@'localhost' IDENTIFIED BY 'DevOps_Pwd123!';
GRANT SELECT ON nanoOrbit_db.* TO 'devops_nano'@'localhost';
GRANT CREATE VIEW , drop ON nanoOrbit_db.* TO 'devops_nano'@'localhost';


-- 2. Révocation des droits d'écriture sur PARTICIPE pour le responsable mission
REVOKE INSERT, UPDATE ON nanoOrbit_db.PARTICIPE FROM 'resp_mission'@'localhost';


-- 3. Accord de la délégation du droit SELECT pour l'administrateur technique
GRANT SELECT ON nanoOrbit_db.* TO 'admin_nano'@'localhost' WITH GRANT OPTION;


-- 4. Vérification finale du privilège de délégation
SHOW GRANTS FOR 'admin_nano'@'localhost';