-----------Packages and exceptions------------------------
--this package manages movie awards — validating, inserting, deleting and querying Movie_Awards
CREATE OR REPLACE PACKAGE pkg_award_manager AS
  PROCEDURE assign_award_to_movie(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  );

  PROCEDURE assign_award_to_actor(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_actor_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  );

  PROCEDURE assign_award_to_staff(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_staff_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  );

  PROCEDURE revoke_award(p_movie_award_id IN NUMBER);

  FUNCTION get_awards_for_movie(p_movie_id IN NUMBER)
    RETURN SYS_REFCURSOR;

  FUNCTION get_awards_for_actor(p_actor_id IN NUMBER)
    RETURN SYS_REFCURSOR;

  FUNCTION get_awards_for_staff(p_staff_id IN NUMBER)
    RETURN SYS_REFCURSOR;
END pkg_award_manager;
/
CREATE OR REPLACE PACKAGE BODY pkg_award_manager AS

  PROCEDURE ensure_movie_exists(p_movie_id IN NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Movie
    WHERE MovieID = p_movie_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20030, 'Movie not found');
    END IF;
  END;


  PROCEDURE ensure_award_exists(p_award_id IN NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Award
    WHERE AwardID = p_award_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20031, 'Award not found');
    END IF;
  END;


  PROCEDURE ensure_actor_exists(p_actor_id IN NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Actor
    WHERE ActorID = p_actor_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20032, 'Actor not found');
    END IF;
  END;


  PROCEDURE ensure_staff_exists(p_staff_id IN NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Production_Staff
    WHERE StaffID = p_staff_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20033, 'Staff not found');
    END IF;
  END;


  PROCEDURE ensure_valid_year(p_year IN NUMBER) IS
  BEGIN
    IF p_year IS NULL OR p_year < 1880 THEN
      RAISE_APPLICATION_ERROR(-20034, 'Invalid year');
    END IF;
  END;


  PROCEDURE ensure_valid_didwin(p_didwin IN CHAR) IS
  BEGIN
    IF NOT (UPPER(TRIM(p_didwin)) IN ('Y', 'N')) THEN
      RAISE_APPLICATION_ERROR(-20035, 'Invalid DidWin');
    END IF;
  END;


  FUNCTION duplicate_award_exists(
    p_movie_id IN NUMBER,
    p_award_id IN NUMBER,
    p_year     IN NUMBER,
    p_actor_id IN NUMBER,
    p_staff_id IN NUMBER
  ) RETURN BOOLEAN IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Movie_Awards
    WHERE MovieID = p_movie_id
      AND AwardID = p_award_id
      AND YearWon = p_year
      AND (
           (Recipient_ActorID = p_actor_id AND p_actor_id IS NOT NULL)
        OR (Recipient_StaffID = p_staff_id AND p_staff_id IS NOT NULL)
        OR (Recipient_ActorID IS NULL AND Recipient_StaffID IS NULL
            AND p_actor_id IS NULL AND p_staff_id IS NULL)
      );

    RETURN v_cnt > 0;
  END;


  PROCEDURE assign_award_to_movie(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  ) IS
    v_id NUMBER;
  BEGIN
    ensure_movie_exists(p_movie_id);
    ensure_award_exists(p_award_id);
    ensure_valid_year(p_year);
    ensure_valid_didwin(p_didwin);

    IF duplicate_award_exists(p_movie_id, p_award_id, p_year, NULL, NULL) THEN
      RAISE_APPLICATION_ERROR(-20037, 'Duplicate award');
    END IF;

    INSERT INTO Movie_Awards (MovieID, AwardID, Recipient_ActorID, Recipient_StaffID, YearWon, DidWin)
    VALUES (p_movie_id, p_award_id, NULL, NULL, p_year, UPPER(p_didwin))
    RETURNING MovieAwardID INTO v_id;

    COMMIT;
    p_out_movie_award_id := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;


  PROCEDURE assign_award_to_actor(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_actor_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  ) IS
    v_id NUMBER;
  BEGIN
    ensure_movie_exists(p_movie_id);
    ensure_award_exists(p_award_id);
    ensure_actor_exists(p_actor_id);
    ensure_valid_year(p_year);
    ensure_valid_didwin(p_didwin);

    IF duplicate_award_exists(p_movie_id, p_award_id, p_year, p_actor_id, NULL) THEN
      RAISE_APPLICATION_ERROR(-20038, 'Duplicate award');
    END IF;

    INSERT INTO Movie_Awards (MovieID, AwardID, Recipient_ActorID, Recipient_StaffID, YearWon, DidWin)
    VALUES (p_movie_id, p_award_id, p_actor_id, NULL, p_year, UPPER(p_didwin))
    RETURNING MovieAwardID INTO v_id;

    COMMIT;
    p_out_movie_award_id := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;


  PROCEDURE assign_award_to_staff(
    p_movie_id           IN NUMBER,
    p_award_id           IN NUMBER,
    p_staff_id           IN NUMBER,
    p_year               IN NUMBER,
    p_didwin             IN CHAR,
    p_out_movie_award_id OUT NUMBER
  ) IS
    v_id NUMBER;
  BEGIN
    ensure_movie_exists(p_movie_id);
    ensure_award_exists(p_award_id);
    ensure_staff_exists(p_staff_id);
    ensure_valid_year(p_year);
    ensure_valid_didwin(p_didwin);

    IF duplicate_award_exists(p_movie_id, p_award_id, p_year, NULL, p_staff_id) THEN
      RAISE_APPLICATION_ERROR(-20039, 'Duplicate award');
    END IF;

    INSERT INTO Movie_Awards (MovieID, AwardID, Recipient_ActorID, Recipient_StaffID, YearWon, DidWin)
    VALUES (p_movie_id, p_award_id, NULL, p_staff_id, p_year, UPPER(p_didwin))
    RETURNING MovieAwardID INTO v_id;

    COMMIT;
    p_out_movie_award_id := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;


  PROCEDURE revoke_award(p_movie_award_id IN NUMBER) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM Movie_Awards
    WHERE MovieAwardID = p_movie_award_id;

    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20040, 'Award not found');
    END IF;

    DELETE FROM Movie_Awards
    WHERE MovieAwardID = p_movie_award_id;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;


  FUNCTION get_awards_for_movie(p_movie_id IN NUMBER)
    RETURN SYS_REFCURSOR
  IS
    rc SYS_REFCURSOR;
  BEGIN
    ensure_movie_exists(p_movie_id);

    OPEN rc FOR
      SELECT ma.MovieAwardID,
             ma.AwardID,
             ma.AwardName,
             ma.ActorID        AS Recipient_ActorID,
             ma.ActorFirstName || ' ' || ma.ActorLastName AS ActorName,
             ma.StaffID        AS Recipient_StaffID,
             ma.StaffFirstName || ' ' || ma.StaffLastName AS StaffName,
             ma.YearWon,
             ma.DidWin
      FROM   vw_movie_awards ma
      WHERE  ma.MovieID = p_movie_id
      ORDER  BY ma.YearWon DESC;

    RETURN rc;
  END;


  FUNCTION get_awards_for_actor(p_actor_id IN NUMBER)
    RETURN SYS_REFCURSOR
  IS
    rc SYS_REFCURSOR;
  BEGIN
    ensure_actor_exists(p_actor_id);

    OPEN rc FOR
      SELECT ma.MovieAwardID,
             ma.MovieID,
             ma.MovieTitle,
             ma.AwardID,
             ma.AwardName,
             ma.YearWon,
             ma.DidWin
      FROM   vw_movie_awards ma
      WHERE  ma.ActorID = p_actor_id
      ORDER  BY ma.YearWon DESC;

    RETURN rc;
  END;


  FUNCTION get_awards_for_staff(p_staff_id IN NUMBER)
    RETURN SYS_REFCURSOR
  IS
    rc SYS_REFCURSOR;
  BEGIN
    ensure_staff_exists(p_staff_id);

    OPEN rc FOR
      SELECT ma.MovieAwardID,
             ma.MovieID,
             ma.MovieTitle,
             ma.AwardID,
             ma.AwardName,
             ma.YearWon,
             ma.DidWin
      FROM   vw_movie_awards ma
      WHERE  ma.StaffID = p_staff_id
      ORDER  BY ma.YearWon DESC;

    RETURN rc;
  END;

END pkg_award_manager;
/

-- Test execution blocks for pkg_award_manager
DECLARE
  v_id NUMBER;
BEGIN
  pkg_award_manager.assign_award_to_movie(
    p_movie_id => 1,
    p_award_id => 2,
    p_year     => 2024,
    p_didwin   => 'N',
    p_out_movie_award_id => v_id
  );
  DBMS_OUTPUT.PUT_LINE('Created MovieAwardID=' || v_id);
END;
/

DECLARE
  v_id NUMBER;
BEGIN
  pkg_award_manager.assign_award_to_actor(
    p_movie_id => 1,
    p_award_id => 3,
    p_actor_id => 5,
    p_year     => 2024,
    p_didwin   => 'Y',
    p_out_movie_award_id => v_id
  );
  DBMS_OUTPUT.PUT_LINE('Created MovieAwardID=' || v_id);
END;
/

DECLARE
  v_id NUMBER;
BEGIN
  pkg_award_manager.assign_award_to_staff(
    p_movie_id => 2,
    p_award_id => 1,
    p_staff_id => 7,
    p_year     => 2023,
    p_didwin   => 'N',
    p_out_movie_award_id => v_id
  );
  DBMS_OUTPUT.PUT_LINE('Created MovieAwardID=' || v_id);
END;
/

BEGIN
  pkg_award_manager.revoke_award(p_movie_award_id => 10);
END;
/

--a movie search package
CREATE OR REPLACE PACKAGE pkg_search AS
  FUNCTION search_movies_by_title(p_title IN VARCHAR2) RETURN SYS_REFCURSOR;
  FUNCTION search_movies_by_actor(p_actor_id IN NUMBER) RETURN SYS_REFCURSOR;
  FUNCTION search_movies_by_genre(p_genre_id IN NUMBER) RETURN SYS_REFCURSOR;
  FUNCTION search_movies_by_year(p_year IN NUMBER) RETURN SYS_REFCURSOR;
END pkg_search;
/

CREATE OR REPLACE PACKAGE BODY pkg_search AS

  FUNCTION search_movies_by_title(p_title IN VARCHAR2) RETURN SYS_REFCURSOR IS rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT MovieID, Title, ReleaseDate, Duration
      FROM Movie
      WHERE LOWER(Title) LIKE LOWER('%' || p_title || '%')
      ORDER BY Title;
    RETURN rc;
  END;

  FUNCTION search_movies_by_actor(p_actor_id IN NUMBER) RETURN SYS_REFCURSOR IS rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT m.MovieID, m.Title, m.ReleaseDate, m.Duration
      FROM Movie m
      JOIN Movie_Cast mc ON m.MovieID = mc.MovieID
      WHERE mc.ActorID = p_actor_id
      ORDER BY m.Title;
    RETURN rc;
  END;

  FUNCTION search_movies_by_genre(p_genre_id IN NUMBER) RETURN SYS_REFCURSOR IS rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT m.MovieID, m.Title, m.ReleaseDate, m.Duration
      FROM Movie m
      JOIN Movie_Genre mg ON m.MovieID = mg.MovieID
      WHERE mg.GenreID = p_genre_id
      ORDER BY m.Title;
    RETURN rc;
  END;

  FUNCTION search_movies_by_year(p_year IN NUMBER) RETURN SYS_REFCURSOR IS rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT MovieID, Title, ReleaseDate, Duration
      FROM Movie
      WHERE EXTRACT(YEAR FROM ReleaseDate) = p_year
      ORDER BY Title;
    RETURN rc;
  END;

END pkg_search;
/

---------------------------------------------------
--helpers to create, remove and check movies
CREATE OR REPLACE PACKAGE pkg_movie_maint AS
  PROCEDURE create_movie_with_genres_and_studios(
    p_title        IN VARCHAR2,
    p_release_date IN DATE,
    p_duration     IN NUMBER,
    p_maturity     IN VARCHAR2,
    p_genre_ids    IN SYS.ODCINUMBERLIST,
    p_studio_ids   IN SYS.ODCINUMBERLIST,
    p_new_movie_id OUT NUMBER
  );

  PROCEDURE delete_movie_safe(p_movie_id IN NUMBER);

  FUNCTION movie_exists(p_movie_id IN NUMBER) RETURN BOOLEAN;
END pkg_movie_maint;
/

CREATE OR REPLACE PACKAGE BODY pkg_movie_maint AS

  PROCEDURE ensure_genre_exists(p_genre_id IN NUMBER) IS v_cnt NUMBER; BEGIN
    SELECT COUNT(*) INTO v_cnt FROM Genre WHERE GenreID = p_genre_id;
    IF v_cnt = 0 THEN RAISE_APPLICATION_ERROR(-20101, 'Genre not found'); END IF;
  END;

  PROCEDURE ensure_studio_exists(p_studio_id IN NUMBER) IS v_cnt NUMBER; BEGIN
    SELECT COUNT(*) INTO v_cnt FROM Studio WHERE StudioID = p_studio_id;
    IF v_cnt = 0 THEN RAISE_APPLICATION_ERROR(-20102, 'Studio not found'); END IF;
  END;

  FUNCTION movie_exists(p_movie_id IN NUMBER) RETURN BOOLEAN IS v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM Movie WHERE MovieID = p_movie_id;
    RETURN v_cnt > 0;
  EXCEPTION WHEN OTHERS THEN RETURN FALSE;
  END movie_exists;

  PROCEDURE create_movie_with_genres_and_studios(
    p_title        IN VARCHAR2,
    p_release_date IN DATE,
    p_duration     IN NUMBER,
    p_maturity     IN VARCHAR2,
    p_genre_ids    IN SYS.ODCINUMBERLIST,
    p_studio_ids   IN SYS.ODCINUMBERLIST,
    p_new_movie_id OUT NUMBER
  ) IS
    v_movie_id NUMBER;
  BEGIN
    IF p_title IS NULL THEN RAISE_APPLICATION_ERROR(-20103, 'Title required'); END IF;
    IF p_duration IS NOT NULL AND p_duration <= 0 THEN RAISE_APPLICATION_ERROR(-20104, 'Invalid duration'); END IF;

    INSERT INTO Movie (Title, ReleaseDate, Synopsis, Duration, MaturityRating)
    VALUES (p_title, p_release_date, NULL, p_duration, p_maturity)
    RETURNING MovieID INTO v_movie_id;

    IF p_genre_ids IS NOT NULL THEN
      FOR i IN 1 .. p_genre_ids.COUNT LOOP
        IF p_genre_ids(i) IS NOT NULL THEN
          ensure_genre_exists(p_genre_ids(i));
          BEGIN
            INSERT INTO Movie_Genre (MovieID, GenreID) VALUES (v_movie_id, p_genre_ids(i));
          EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
          END;
        END IF;
      END LOOP;
    END IF;

    IF p_studio_ids IS NOT NULL THEN
      FOR i IN 1 .. p_studio_ids.COUNT LOOP
        IF p_studio_ids(i) IS NOT NULL THEN
          ensure_studio_exists(p_studio_ids(i));
          BEGIN
            INSERT INTO Movie_Studio (MovieID, StudioID) VALUES (v_movie_id, p_studio_ids(i));
          EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
          END;
        END IF;
      END LOOP;
    END IF;

    COMMIT;
    p_new_movie_id := v_movie_id;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END create_movie_with_genres_and_studios;

  PROCEDURE delete_movie_safe(p_movie_id IN NUMBER) IS
    v_cnt NUMBER;
    v_old CLOB;
    v_title VARCHAR2(4000);
    v_release DATE;
    v_duration NUMBER;
    v_maturity VARCHAR2(100);
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM Movie WHERE MovieID = p_movie_id;
    IF v_cnt = 0 THEN RAISE_APPLICATION_ERROR(-20105, 'Movie not found'); END IF;

    SELECT Title, ReleaseDate, Duration, MaturityRating
      INTO v_title, v_release, v_duration, v_maturity
      FROM Movie WHERE MovieID = p_movie_id;

    v_old := 'MovieID=' || p_movie_id || '; Title=' || NVL(v_title,'NULL') ||
             '; ReleaseDate=' || NVL(TO_CHAR(v_release,'YYYY-MM-DD'), 'NULL') ||
             '; Duration=' || NVL(TO_CHAR(v_duration), 'NULL') ||
             '; Maturity=' || NVL(v_maturity,'NULL');

    INSERT INTO Audit_Log (TableName, Operation, OldData, NewData)
    VALUES ('MOVIE', 'DELETE', v_old, NULL);

    DELETE FROM Movie WHERE MovieID = p_movie_id;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END delete_movie_safe;

END pkg_movie_maint;
/

--example test block
DECLARE
  v_new_id NUMBER;
BEGIN
  pkg_movie_maint.create_movie_with_genres_and_studios(
    p_title        => 'Test Movie X',
    p_release_date => DATE '2024-12-05',
    p_duration     => 130,
    p_maturity     => 'PG-13',
    p_genre_ids    => SYS.ODCINUMBERLIST(1, 2),
    p_studio_ids   => SYS.ODCINUMBERLIST(1, 3),
    p_new_movie_id => v_new_id
  );

  DBMS_OUTPUT.PUT_LINE('Created MovieID = ' || v_new_id);
END;
/