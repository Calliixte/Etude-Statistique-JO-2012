--Medailles pour les épreuves en solo, comptage individuel pour ensuite additionner le tout, on sépare les deux cas pour limiter les duplicatas liés aux join
CREATE OR REPLACE VIEW MEDAILLES_INDIVIDUELLES AS
SELECT
	IDATHLETE, SUM(CASE WHEN MEDAILLE = 'Gold' THEN 1 ELSE 0 END) AS OR_MEDAILLES,
	SUM(CASE WHEN MEDAILLE = 'Silver' THEN 1 ELSE 0 END) AS ARGENT_MEDAILLES,
	SUM(CASE WHEN MEDAILLE = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE_MEDAILLES,
	COUNT(MEDAILLE) AS TOTAL_MEDAILLES
FROM
	PARTICIPATION_INDIVIDUELLE pi
GROUP BY
	IDATHLETE;


--Medailles pour les épreuves en équipe
CREATE OR REPLACE VIEW MEDAILLES_EQUIPE AS
SELECT
ce.IDATHLETE,
SUM(CASE WHEN pe.MEDAILLE = 'Gold' THEN 1 ELSE 0 END) AS OR_MEDAILLES,
SUM(CASE WHEN pe.MEDAILLE = 'Silver' THEN 1 ELSE 0 END) AS ARGENT_MEDAILLES,
SUM(CASE WHEN pe.MEDAILLE = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE_MEDAILLES,
COUNT(pe.MEDAILLE) AS TOTAL_MEDAILLES
FROM
PARTICIPATION_EQUIPE pe
INNER JOIN
COMPOSITION_EQUIPE ce ON pe.IDEQUIPE = ce.IDEQUIPE
GROUP BY
ce.IDATHLETE;

--Creation de la vue finale
CREATE OR REPLACE VIEW MEDAILLES_ATHLETES AS
SELECT
	a.IDATHLETE,
	a.NOMATHLETE,
	a.PRENOMATHLETE,
	-- Utilisation de NVL pour traiter les valeurs NULL comme 0
	NVL(mi.OR_MEDAILLES, 0) + NVL(me.OR_MEDAILLES, 0) AS OR_MEDAILLES,
	NVL(mi.ARGENT_MEDAILLES, 0) + NVL(me.ARGENT_MEDAILLES, 0) AS ARGENT_MEDAILLES,
	NVL(mi.BRONZE_MEDAILLES, 0) + NVL(me.BRONZE_MEDAILLES, 0) AS BRONZE_MEDAILLES,
	NVL(mi.TOTAL_MEDAILLES, 0) + NVL(me.TOTAL_MEDAILLES, 0) AS TOTAL_MEDAILLES
FROM
	ATHLETE a
LEFT JOIN
	MEDAILLES_INDIVIDUELLES mi ON a.IDATHLETE = mi.IDATHLETE
LEFT JOIN
	MEDAILLES_EQUIPE me ON a.IDATHLETE = me.IDATHLETE
ORDER BY
	OR_MEDAILLES DESC,
	ARGENT_MEDAILLES DESC,
	BRONZE_MEDAILLES DESC,
	TOTAL_MEDAILLES DESC,
	a.NOMATHLETE ASC,
	a.PRENOMATHLETE ASC,
	a.IDATHLETE ASC;

--Medailles pour les épreuves en solo, comptage individuel pour ensuite additionner le tout, on sépare les deux cas pour limiter les duplicatas liés aux join
CREATE OR REPLACE VIEW MEDAILLES_INDIVIDUELLES_NOC AS
SELECT
    n.codenoc, SUM(CASE WHEN MEDAILLE = 'Gold' THEN 1 ELSE 0 END) AS OR_MEDAILLES,
    SUM(CASE WHEN MEDAILLE = 'Silver' THEN 1 ELSE 0 END) AS ARGENT_MEDAILLES,
    SUM(CASE WHEN MEDAILLE = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE_MEDAILLES,
    COUNT(MEDAILLE) AS TOTAL_MEDAILLES
FROM
    PARTICIPATION_INDIVIDUELLE pi
INNER JOIN
	noc n on pi.noc=n.codenoc
GROUP BY
    n.codenoc;


--Medailles pour les épreuves en équipe
CREATE OR REPLACE VIEW MEDAILLES_EQUIPE_NOC AS
SELECT
n.codenoc,
SUM(CASE WHEN pe.MEDAILLE = 'Gold' THEN 1 ELSE 0 END) AS OR_MEDAILLES,
SUM(CASE WHEN pe.MEDAILLE = 'Silver' THEN 1 ELSE 0 END) AS ARGENT_MEDAILLES,
SUM(CASE WHEN pe.MEDAILLE = 'Bronze' THEN 1 ELSE 0 END) AS BRONZE_MEDAILLES,
COUNT(pe.MEDAILLE) AS TOTAL_MEDAILLES
FROM
PARTICIPATION_EQUIPE pe
INNER JOIN
	equipe e on pe.idequipe=e.idequipe
inner join
	noc n on e.noc=n.codenoc
GROUP BY
n.codenoc;

--Creation de la vue finale
CREATE OR REPLACE VIEW MEDAILLES_NOC AS
SELECT
    
    
    NVL(mi.OR_MEDAILLES, 0) + NVL(me.OR_MEDAILLES, 0) AS OR_MEDAILLES,
    NVL(mi.ARGENT_MEDAILLES, 0) + NVL(me.ARGENT_MEDAILLES, 0) AS ARGENT_MEDAILLES,
    NVL(mi.BRONZE_MEDAILLES, 0) + NVL(me.BRONZE_MEDAILLES, 0) AS BRONZE_MEDAILLES,
    NVL(mi.TOTAL_MEDAILLES, 0) + NVL(me.TOTAL_MEDAILLES, 0) AS TOTAL_MEDAILLES
FROM
    noc n
LEFT JOIN
    MEDAILLES_INDIVIDUELLES_NOC mi ON n.codenoc = mi.codenoc
LEFT JOIN
    MEDAILLES_EQUIPE_NOC me ON n.codenoc = me.codenoc
ORDER BY
    OR_MEDAILLES DESC,
    ARGENT_MEDAILLES DESC,
    BRONZE_MEDAILLES DESC,
    TOTAL_MEDAILLES DESC,
    n.codenoc ASC;

CREATE OR REPLACE FUNCTION biographie (id_athlete IN NUMBER) RETURN CLOB AS
    obj_json clob;
    gold int;
    argent int;
    bronze int;
    total int;
BEGIN
    -- Vérifier si l'athlète existe
    SELECT COUNT(*) INTO total FROM Athlete WHERE idathlete = id_athlete;
    IF total = 0 THEN
        -- Lancer une exception si l'athlète n'existe pas
        RAISE_APPLICATION_ERROR(-20011, 'Athlète inconnu');
    END IF;
    
    -- Sélectionner les médailles de l'athlète
    SELECT OR_MEDAILLES, ARGENT_MEDAILLES, BRONZE_MEDAILLES, TOTAL_MEDAILLES
    INTO gold, argent, bronze, total
    FROM MEDAILLES_ATHLETES
    WHERE MEDAILLES_ATHLETES.idathlete = id_athlete;

    -- Sélectionner les informations de l'athlète
    SELECT JSON_OBJECT(
               'nom'    VALUE NomAthlete,
               'prénom' VALUE PrenomAthlete,
               'surnom'        VALUE Surnom,
               'genre'         VALUE SUBSTR(Genre, 1, 1),
               'dateNaissance' VALUE TO_CHAR(DateNaissance, 'YYYY-MM-DD'),
               'dateDécès'     VALUE TO_CHAR(DateDeces, 'YYYY-MM-DD'),
               'taille'        VALUE Taille || ' cm',
               'poids'         VALUE Poids || ' kg',
               'médaillesOr'   VALUE TO_CHAR(gold),
               'médaillesArgent'   VALUE TO_CHAR(argent),
               'médaillesBronze'   VALUE TO_CHAR(bronze),
               'médaillesTotal'   VALUE TO_CHAR(total)
           )
    INTO obj_json
    FROM Athlete
    WHERE idathlete = id_athlete;
    
    RETURN obj_json;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Gérer l'exception si aucune ligne n'est trouvée
        RAISE_APPLICATION_ERROR(-20011, 'Athlète inconnu');
END;
/

CREATE OR REPLACE PROCEDURE ajouter_resultat_individuel(
	id_evenement NUMBER,
	id_athlete NUMBER,
	code_noc VARCHAR2,
	resultat VARCHAR2
)
AS
	varCheckPres NUMBER(10);
	varCheckEven BOOLEAN := FALSE;
	varCheckAthl BOOLEAN := FALSE;
	varCheckNOC BOOLEAN := FALSE;
	resultValid BOOLEAN := TRUE;
	resultegalvalid BOOLEAN := FALSE;
	eventStatus VARCHAR2(30);
	medailleObtenue VARCHAR2(10);
	NOCAthlete VARCHAR2(10);

	CURSOR medailles IS
    	SELECT pi.resultat result, medaille
    	FROM participation_individuelle pi
    	WHERE idevent = id_evenement;

	CURSOR liste_resultat IS
    	SELECT pi.resultat
    	FROM participation_individuelle pi
    	WHERE idevent = id_evenement;

	CURSOR participants_event IS
    	SELECT idathlete
    	FROM participation_individuelle pi
    	WHERE idevent = id_evenement;

	CURSOR liste_athlete IS
    	SELECT idathlete
    	FROM athlete;

	CURSOR liste_event IS
    	SELECT idevenement
    	FROM evenement;

	CURSOR liste_noc IS
    	SELECT codenoc
    	FROM noc;

	-- Déclaration de l'exception
	INEXISTANT EXCEPTION;
	PRAGMA EXCEPTION_INIT(INEXISTANT, -20001);
	POSOCCUPEE EXCEPTION;
	PRAGMA EXCEPTION_INIT(POSOCCUPEE, -20002);
	DEJAPRESENT EXCEPTION;
	PRAGMA EXCEPTION_INIT(DEJAPRESENT, -20003);
	NOTNOC EXCEPTION;
	PRAGMA EXCEPTION_INIT(NOTNOC, -20004);
 
BEGIN
	-- verification de l'existence de l'athlete, l'evenement et du noc

	-- Athlete
	FOR ligne IN liste_athlete
	LOOP
    	IF id_athlete = ligne.idathlete THEN
			varCheckAthl := TRUE;
    	END IF;
	END LOOP;

	IF varCheckAthl = FALSE THEN
    	RAISE INEXISTANT;
	END IF;

	-- Evenement
	FOR ligne IN liste_event
	LOOP
    	IF id_evenement = ligne.idevenement THEN
			varCheckEven := TRUE;
    	END IF;
	END LOOP;

	IF NOT varCheckEven THEN
    	RAISE INEXISTANT;
	END IF;

	-- NOC
	FOR ligne IN liste_noc
	LOOP
    	IF code_noc = ligne.codenoc THEN
			varCheckNOC := TRUE;
    	END IF;
	END LOOP;

	IF NOT varCheckNOC THEN
    	RAISE INEXISTANT;
	END IF;

	-- verification de si l'athlete a déjà un résultat pour ladite épreuve
	FOR ligne IN participants_event
	LOOP
    	IF id_athlete = ligne.idathlete THEN
			RAISE DEJAPRESENT;
    	END IF;
	END LOOP;

	-- Verification de la validité du résultat
	resultValid := TRUE;
	FOR ligneC IN liste_resultat
	LOOP
    	IF SUBSTR(ligneC.resultat, 1, 1) = '=' THEN
			IF SUBSTR(ligneC.resultat, 1, 3) = SUBSTR(resultat, 1, 3) THEN
				resultValid := TRUE;
				resultegalvalid := TRUE;
			ELSE
				IF resultegalvalid = FALSE THEN
					resultValid := FALSE;
				END IF;
			END IF;  
    	ELSE
			IF SUBSTR(ligneC.resultat, 1, 2) = SUBSTR(resultat, 1, 2) THEN
				resultValid := FALSE;    
			END IF;
    	END IF;
	END LOOP;

	IF resultValid = FALSE THEN
    	RAISE POSOCCUPEE;
	END IF;

	-- Mise en place de la medaille
	-- 1) verification de si l'evenement est bien olympique ou intercalé
	-- 2) application du texte en fonction de la medaille
	SELECT DISTINCT statutevenement
	INTO eventStatus
	FROM evenement e
	WHERE e.idevenement = id_evenement;

	IF eventStatus = 'Olympic' OR eventStatus = 'Intercalated' THEN
    	IF resultegalvalid THEN
			IF SUBSTR(resultat, 1, 2) = '=1' THEN
				medailleObtenue := 'Gold';
			ELSIF SUBSTR(resultat, 1, 2) = '=2' THEN
				medailleObtenue := 'Silver';
			ELSIF SUBSTR(resultat, 1, 2) = '=3' THEN
				medailleObtenue := 'Bronze';
			ELSE
				medailleObtenue := NULL;
			END IF;
    	ELSE
			IF SUBSTR(resultat, 1, 1) = '1' THEN
				medailleObtenue := 'Gold';
			ELSIF SUBSTR(resultat, 1, 1) = '2' THEN
				medailleObtenue := 'Silver';
			ELSIF SUBSTR(resultat, 1, 1) = '3' THEN
				medailleObtenue := 'Bronze';
			ELSE
				medailleObtenue := NULL;
			END IF;
    	END IF;
	ELSE
    	medailleObtenue := NULL;
	END IF;

	-- Verification de la cohérence du NOC
	SELECT DISTINCT noc
	INTO NOCAthlete
	FROM participation_individuelle
	WHERE idathlete = id_athlete;

	IF NOCAthlete IS NOT NULL THEN
    	IF NOCAthlete != code_noc THEN
			RAISE NOTNOC;
    	END IF;
	END IF;

	-- Insertion Finale
	INSERT INTO participation_individuelle VALUES (id_athlete, id_evenement, resultat, medailleObtenue, code_noc);

EXCEPTION
	WHEN INEXISTANT THEN
  	  IF varCheckAthl = false THEN RAISE_APPLICATION_ERROR(-20001, 'Athlète inexistant'); END IF;
  	  IF varCheckEven = false THEN RAISE_APPLICATION_ERROR(-20001, 'Événement inexistant'); END IF;
  	  IF varCheckNoc = false THEN RAISE_APPLICATION_ERROR(-20001, 'NOC inexistant'); END IF;
	WHEN DEJAPRESENT THEN
    	RAISE_APPLICATION_ERROR(-20003, 'Athlète déjà classé');
	WHEN POSOCCUPEE THEN
    	RAISE_APPLICATION_ERROR(-20002, 'Position déjà occupée');
	WHEN NOTNOC THEN
    	RAISE_APPLICATION_ERROR(-20004, 'Incohérence de NOC');
END;
/

CREATE OR REPLACE PROCEDURE ajouter_resultat_equipe(
	id_evenement NUMBER,
	id_equipe NUMBER,
	resultat VARCHAR2
)
AS
	varCheckEven BOOLEAN := FALSE;
	varCheckEquipe BOOLEAN := FALSE;
	resultValid BOOLEAN := TRUE;
	resultegalvalid BOOLEAN := FALSE;
	eventStatus VARCHAR2(30);
	medailleObtenue VARCHAR2(10);

	CURSOR medailles IS
    	SELECT pe.resultat result, medaille
    	FROM participation_equipe pe
    	WHERE idevenement = id_evenement;

	CURSOR liste_resultat IS
    	SELECT pe.resultat
    	FROM participation_equipe pe
    	WHERE idevenement = id_evenement;

	CURSOR participants_event IS
    	SELECT idequipe
    	FROM participation_equipe pe
    	WHERE idevenement = id_evenement;

	CURSOR liste_equipe IS
    	SELECT idequipe
    	FROM equipe;

	CURSOR liste_event IS
    	SELECT idevenement
    	FROM evenement;

	-- Déclaration de l'exception
	INEXISTANT EXCEPTION;
	PRAGMA EXCEPTION_INIT(INEXISTANT, -20001);
	POSOCCUPEE EXCEPTION;
	PRAGMA EXCEPTION_INIT(POSOCCUPEE, -20002);
	DEJAPRESENT EXCEPTION;
	PRAGMA EXCEPTION_INIT(DEJAPRESENT, -20003);

BEGIN
	-- verification de l'existence de l'équipe et de l'événement

	-- Équipe
	FOR ligne IN liste_equipe
	LOOP
    	IF id_equipe = ligne.idequipe THEN
        	varCheckEquipe := TRUE;
    	END IF;
	END LOOP;

	IF NOT varCheckEquipe THEN
    	RAISE INEXISTANT;
	END IF;

	-- Evenement
	FOR ligne IN liste_event
	LOOP
    	IF id_evenement = ligne.idevenement THEN
        	varCheckEven := TRUE;
    	END IF;
	END LOOP;

	IF NOT varCheckEven THEN
    	RAISE INEXISTANT;
	END IF;

	-- verification de si l'équipe a déjà un résultat pour ledit épreuve
	FOR ligne IN participants_event
	LOOP
    	IF id_equipe = ligne.idequipe THEN
        	RAISE DEJAPRESENT;
    	END IF;
	END LOOP;

	-- Verification de la validité du résultat
	resultValid := TRUE;
	FOR ligneC IN liste_resultat
	LOOP
    	IF SUBSTR(ligneC.resultat, 1, 1) = '=' THEN
        	IF SUBSTR(ligneC.resultat, 1, 3) = SUBSTR(resultat, 1, 3) THEN
            	resultValid := TRUE;
            	resultegalvalid := TRUE;
        	ELSE
            	IF resultegalvalid = FALSE THEN
                	resultValid := FALSE;
            	END IF;
        	END IF;  
    	ELSE
        	IF SUBSTR(ligneC.resultat, 1, 2) = SUBSTR(resultat, 1, 2) THEN
            	resultValid := FALSE;    
        	END IF;
    	END IF;
	END LOOP;

	IF resultValid = FALSE THEN
    	RAISE POSOCCUPEE;
	END IF;

	-- Mise en place de la medaille
	-- 1) verification de si l'evenement est bien olympique ou intercalé
	-- 2) application du texte en fonction de la medaille
	SELECT DISTINCT statutevenement
	INTO eventStatus
	FROM evenement e
	WHERE e.idevenement = id_evenement;

	IF eventStatus = 'Olympic' OR eventStatus = 'Intercalated' THEN
    	IF resultegalvalid THEN
        	IF SUBSTR(resultat, 1, 2) = '=1' THEN
            	medailleObtenue := 'Gold';
        	ELSIF SUBSTR(resultat, 1, 2) = '=2' THEN
            	medailleObtenue := 'Silver';
        	ELSIF SUBSTR(resultat, 1, 2) = '=3' THEN
            	medailleObtenue := 'Bronze';
        	ELSE
            	medailleObtenue := NULL;
        	END IF;
    	ELSE
        	IF SUBSTR(resultat, 1, 1) = '1' THEN
            	medailleObtenue := 'Gold';
        	ELSIF SUBSTR(resultat, 1, 1) = '2' THEN
            	medailleObtenue := 'Silver';
        	ELSIF SUBSTR(resultat, 1, 1) = '3' THEN
            	medailleObtenue := 'Bronze';
        	ELSE
            	medailleObtenue := NULL;
        	END IF;
    	END IF;
	ELSE
    	medailleObtenue := NULL;
	END IF;

	-- Insertion Finale
	INSERT INTO participation_equipe VALUES (id_equipe, id_evenement, resultat, medailleObtenue);

EXCEPTION
	WHEN INEXISTANT THEN
    	IF varCheckEquipe = false THEN RAISE_APPLICATION_ERROR(-20001, 'Équipe inexistante'); END IF;
    	IF varCheckEven = false THEN RAISE_APPLICATION_ERROR(-20001, 'Événement inexistant'); END IF;
	WHEN DEJAPRESENT THEN
    	RAISE_APPLICATION_ERROR(-20003, 'Équipe déjà classée');
	WHEN POSOCCUPEE THEN
    	RAISE_APPLICATION_ERROR(-20002, 'Position déjà occupée');
	WHEN OTHERS THEN
    	RAISE_APPLICATION_ERROR(-20005, 'Erreur inconnue : ' || SQLERRM);
END;
/

-- Table log 

CREATE TABLE LOG (
	idLog NUMBER GENERATED ALWAYS AS IDENTITY,
	idAuteur VARCHAR2(100) NOT NULL,
	action VARCHAR2(20) NOT NULL,
	dateHeureAction TIMESTAMP NOT NULL,
	ligneAvant VARCHAR2(4000),
	ligneApres VARCHAR2(4000),
	PRIMARY KEY (idLog)
);

--Exemple de trigger utilisé sur LOG, vous pouvez trouver le reste dans le pdf joint 

CREATE OR REPLACE TRIGGER disciplineTrigger
AFTER INSERT OR DELETE OR UPDATE ON DISCIPLINE
FOR EACH ROW
DECLARE
	auteurid NUMBER;
    ancienneLigne VARCHAR2(4000);
    nouvelleLigne VARCHAR2(4000);
BEGIN
	SELECT USER_ID
	INTO auteurid
	FROM ALL_USERS
	WHERE USERNAME = USER;
   
	IF INSERTING THEN
  	  ancienneLigne:=null;
   	  nouvelleLigne := :NEW.codeDiscipline ||',' ||:NEW.NOMDISCIPLINE ||','|| :NEW.CODESPORT;
  	  INSERT INTO LOG (idAuteur, action, dateHeureAction, ligneAvant, ligneApres) VALUES
  	  (auteurid, 'Insertion', SUBSTR(CURRENT_TIMESTAMP,0,16), ancienneLigne, nouvelleLigne);
	END IF;
    
	IF UPDATING THEN
     ancienneLigne := :OLD.codeDiscipline ||',' ||:OLD.NOMDISCIPLINE ||','|| :OLD.CODESPORT;
	nouvelleLigne := :NEW.codeDiscipline ||',' ||:NEW.NOMDISCIPLINE ||','|| :NEW.CODESPORT;
  	  INSERT INTO LOG (idAuteur, action, dateHeureAction, ligneAvant, ligneApres) VALUES   
  	  (auteurid, 'Mise a Jour', SUBSTR(CURRENT_TIMESTAMP,0,16), ancienneLigne, nouvelleLigne);
	END IF;
	IF DELETING THEN
     ancienneLigne := :OLD.codeDiscipline ||',' ||:OLD.NOMDISCIPLINE ||','|| :OLD.CODESPORT;
     nouvelleLigne := null;
  	  INSERT INTO LOG (idAuteur, action, dateHeureAction, ligneAvant, ligneApres) VALUES   
  	  (auteurid, 'Suppression', SUBSTR(CURRENT_TIMESTAMP,0,16), ancienneLigne, nouvelleLigne);
	END IF;
END;
/