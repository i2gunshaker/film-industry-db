----------------------------Triggers---------------------------------------
--log changes in the Audit_Log table
CREATE OR REPLACE TRIGGER trg_audit_movie
AFTER INSERT OR UPDATE OR DELETE ON Movie
FOR EACH ROW
DECLARE
    v_op   VARCHAR2(10);
    v_old  CLOB;
    v_new  CLOB;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT';
        v_old := NULL;
        v_new := 'MovieID=' || NVL(TO_CHAR(:NEW.MovieID),'NULL') ||
                 ', Title=' || NVL(:NEW.Title,'NULL') ||
                 ', ReleaseDate=' || NVL(TO_CHAR(:NEW.ReleaseDate,'YYYY-MM-DD'),'NULL') ||
                 ', Duration=' || NVL(TO_CHAR(:NEW.Duration),'NULL');
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
        v_old := 'MovieID=' || NVL(TO_CHAR(:OLD.MovieID),'NULL') ||
                 ', Title=' || NVL(:OLD.Title,'NULL') ||
                 ', ReleaseDate=' || NVL(TO_CHAR(:OLD.ReleaseDate,'YYYY-MM-DD'),'NULL') ||
                 ', Duration=' || NVL(TO_CHAR(:OLD.Duration),'NULL');
        v_new := 'MovieID=' || NVL(TO_CHAR(:NEW.MovieID),'NULL') ||
                 ', Title=' || NVL(:NEW.Title,'NULL') ||
                 ', ReleaseDate=' || NVL(TO_CHAR(:NEW.ReleaseDate,'YYYY-MM-DD'),'NULL') ||
                 ', Duration=' || NVL(TO_CHAR(:NEW.Duration),'NULL');
    ELSIF DELETING THEN
        v_op := 'DELETE';
        v_old := 'MovieID=' || NVL(TO_CHAR(:OLD.MovieID),'NULL') ||
                 ', Title=' || NVL(:OLD.Title,'NULL');
        v_new := NULL;
    END IF;
    INSERT INTO Audit_Log (TableName, Operation, OldData, NewData, ChangeTimestamp, ChangedBy)
    VALUES ('Movie', v_op, v_old, v_new, SYSTIMESTAMP, USER);
END;
/


--Do not allow YearWon to be specified before the year of release (or an irrelevant earlier year) and no later than the current year
CREATE OR REPLACE TRIGGER trg_awards_validate_year
BEFORE INSERT OR UPDATE ON Movie_Awards
FOR EACH ROW
DECLARE
    v_release DATE;
    v_release_year NUMBER;
    v_current_year NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY'));
BEGIN
    SELECT ReleaseDate INTO v_release FROM Movie WHERE MovieID = :NEW.MovieID;

    IF v_release IS NOT NULL THEN
        v_release_year := TO_NUMBER(TO_CHAR(v_release,'YYYY'));
        IF :NEW.YearWon < v_release_year THEN
            RAISE_APPLICATION_ERROR(-20003, 'YearWon cannot be less than the year of the films release.');
        END IF;
    END IF;
    IF :NEW.YearWon > v_current_year THEN
        RAISE_APPLICATION_ERROR(-20004, 'YearWon cannot be greater than the current year.');
    END IF;
END;
/

----------------------------------------------------test---------------------------------------------------
-- SELECT Trigger_Name, Status FROM USER_TRIGGERS WHERE Trigger_Name = 'TRG_AWARDS_VALIDATE_YEAR';
-- ALTER TRIGGER WKSP_ARAILYMAZATKYZY.TRG_AUDIT_MOVIE DISABLE;

INSERT INTO Movie (Title, ReleaseDate, Duration)
VALUES ('__TEST_MOVIE_AWARDS__', TO_DATE('2018-05-20','YYYY-MM-DD'), 110);
COMMIT;

INSERT INTO Award (AwardName, AwardingBody)
VALUES ('__TEST_AWARD__', 'TestBody');
COMMIT;

DECLARE
    v_movie_id NUMBER;
    v_award_id NUMBER;
BEGIN
    SELECT MovieID INTO v_movie_id FROM Movie WHERE Title = '__TEST_MOVIE_AWARDS__' AND ROWNUM = 1;
    SELECT AwardID  INTO v_award_id  FROM Award WHERE AwardName = '__TEST_AWARD__' AND ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('finded MovieID = ' || v_movie_id || ', AwardID = ' || v_award_id);
    BEGIN
        INSERT INTO Movie_Awards (MovieID, AwardID, YearWon, DidWin)
        VALUES (v_movie_id, v_award_id, 2016, 'N'); 
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('wow: insertion with YearWon = 2016 worked (unexpectedly).');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error when YearWon < Release Date:' || SQLERRM);
            ROLLBACK;
    END;
    BEGIN
        INSERT INTO Movie_Awards (MovieID, AwardID, YearWon, DidWin)
        VALUES (v_movie_id, v_award_id, TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) + 1, 'N'); 
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('wow: the insert with YearWon in the future went through (unexpectedly).');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error when YearWon > current year:' || SQLERRM);
            ROLLBACK;
    END;
    BEGIN
        INSERT INTO Movie_Awards (MovieID, AwardID, YearWon, DidWin)
        VALUES (v_movie_id, v_award_id, 2018, 'N'); 
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Correct insertion with YearWon = 2018 completed successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('UNEXPECTED error while inserting correctly: ' || SQLERRM);
            ROLLBACK;
    END;
    FOR r IN (
        SELECT MovieAwardID, MovieID, AwardID, YearWon, DidWin
        FROM Movie_Awards
        WHERE MovieID = v_movie_id
        ORDER BY MovieAwardID
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Movie_Awards row: ID='||r.MovieAwardID||' MovieID='||r.MovieID||
                             ' AwardID='||r.AwardID||' YearWon='||r.YearWon||' DidWin='||r.DidWin);
    END LOOP;
END;
/

-- SELECT MovieAwardID, MovieID, AwardID, YearWon, DidWin FROM Movie_Awards WHERE MovieID IN (SELECT MovieID FROM Movie WHERE Title = '__TEST_MOVIE_AWARDS__');

DELETE FROM Movie_Awards WHERE MovieID IN (SELECT MovieID FROM Movie WHERE Title = '__TEST_MOVIE_AWARDS__');
DELETE FROM Award WHERE AwardName = '__TEST_AWARD__';
DELETE FROM Movie WHERE Title = '__TEST_MOVIE_AWARDS__';
COMMIT;

--cannot insert/update a movie if Release Date > current date.
CREATE OR REPLACE TRIGGER trg_movie_no_future_release
BEFORE INSERT OR UPDATE ON Movie
FOR EACH ROW
BEGIN
    IF :NEW.ReleaseDate IS NOT NULL AND :NEW.ReleaseDate > TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20001, 'ReleaseDate cannot be in the future.');
    END IF;
    IF :NEW.Duration IS NOT NULL AND :NEW.Duration <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Duration must be greater than 0.');
    END IF;
END;
/

--An actor cannot play in a film if he was born after the release date.
CREATE OR REPLACE TRIGGER trg_movie_cast_actor_dob_check
BEFORE INSERT OR UPDATE ON Movie_Cast
FOR EACH ROW
DECLARE
    v_actor_dob   DATE;
    v_release_dt  DATE;
BEGIN
    SELECT DateOfBirth INTO v_actor_dob FROM Actor WHERE ActorID = :NEW.ActorID;
    SELECT ReleaseDate INTO v_release_dt FROM Movie WHERE MovieID = :NEW.MovieID;

    IF v_release_dt IS NOT NULL AND v_actor_dob IS NOT NULL AND v_actor_dob > v_release_dt THEN
        RAISE_APPLICATION_ERROR(-20020, 'Actor.DateOfBirth is later than the movies ReleaseDate pls check the data.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'Actor or Movie not found when checking Movie_Cast...');
END;
/

--Block studio deletion if it's associated with movies 
CREATE OR REPLACE TRIGGER trg_studio_prevent_delete_if_in_use
BEFORE DELETE ON Studio
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Movie_Studio WHERE StudioID = :OLD.StudioID;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Cannot delete studio: there are related films.');
    END IF;
END;
/
--Award recipient must belong to that movie
CREATE OR REPLACE TRIGGER trg_award_recipient_must_be_in_movie
BEFORE INSERT OR UPDATE ON Movie_Awards
FOR EACH ROW
DECLARE
    v_cnt NUMBER;
BEGIN
    IF :NEW.Recipient_ActorID IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cnt
        FROM Movie_Cast
        WHERE MovieID = :NEW.MovieID
          AND ActorID = :NEW.Recipient_ActorID;

        IF v_cnt = 0 THEN
            RAISE_APPLICATION_ERROR(-20110,
              'Award recipient actor is not in this movie''s cast.');
        END IF;
    ELSIF :NEW.Recipient_StaffID IS NOT NULL THEN
        SELECT COUNT(*) INTO v_cnt
        FROM Movie_Crew
        WHERE MovieID = :NEW.MovieID
          AND StaffID = :NEW.Recipient_StaffID;

        IF v_cnt = 0 THEN
            RAISE_APPLICATION_ERROR(-20111,
              'Award recipient staff is not in this movie crew.');
        END IF;
    END IF;
END;
/
--Studio cannot be attached to a movie before it was founded
CREATE OR REPLACE TRIGGER trg_movie_studio_year_check
BEFORE INSERT OR UPDATE ON Movie_Studio
FOR EACH ROW
DECLARE
    v_release_year NUMBER;
    v_founded_year NUMBER;
BEGIN
    SELECT EXTRACT(YEAR FROM ReleaseDate)
      INTO v_release_year
      FROM Movie
     WHERE MovieID = :NEW.MovieID;

    SELECT YearFounded
      INTO v_founded_year
      FROM Studio
     WHERE StudioID = :NEW.StudioID;

    IF v_release_year IS NOT NULL
       AND v_founded_year IS NOT NULL
       AND v_release_year < v_founded_year THEN
        RAISE_APPLICATION_ERROR(-20120,
          'Studio cannot be attached to a movie released before it was founded.');
    END IF;
END;
/