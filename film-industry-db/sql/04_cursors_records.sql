--------------------Cursor and records----------------------------------
--CURSOR calculates the number of films for each actor
DECLARE
    CURSOR cur_actors IS
        SELECT ActorID, FirstName, LastName FROM Actor;

    rec_actor cur_actors%ROWTYPE;
    v_movie_count NUMBER;
    v_avg_rating  NUMBER;
BEGIN
    OPEN cur_actors;
    LOOP
        FETCH cur_actors INTO rec_actor;
        EXIT WHEN cur_actors%NOTFOUND;

        SELECT COUNT(DISTINCT mc.MovieID)
          INTO v_movie_count
          FROM Movie_Cast mc
         WHERE mc.ActorID = rec_actor.ActorID;
        SELECT AVG(r.RatingScore)
          INTO v_avg_rating
          FROM Review r
          JOIN Movie_Cast mc2 ON r.MovieID = mc2.MovieID
         WHERE mc2.ActorID = rec_actor.ActorID;
        DBMS_OUTPUT.PUT_LINE(
            rec_actor.ActorID || ' | ' ||
            rec_actor.FirstName || ' ' || rec_actor.LastName ||
            ' | Movies: ' || NVL(TO_CHAR(v_movie_count), '0') ||
            ' | AvgRating: ' || NVL(TO_CHAR(ROUND(v_avg_rating,2)), 'N/A')
        );
    END LOOP;
    CLOSE cur_actors;
END;
/

--CURSOR report by year by awards
DECLARE
    CURSOR cur_awards IS
        SELECT ma.YearWon,
               aw.AwardName,
               m.Title AS MovieTitle,
               a.FirstName AS ActorFirst,
               a.LastName  AS ActorLast,
               ps.FirstName AS StaffFirst,
               ps.LastName  AS StaffLast,
               ma.DidWin
        FROM Movie_Awards ma
        LEFT JOIN Movie m ON ma.MovieID = m.MovieID
        LEFT JOIN Award aw  ON ma.AwardID = aw.AwardID
        LEFT JOIN Actor a   ON ma.Recipient_ActorID = a.ActorID
        LEFT JOIN Production_Staff ps ON ma.Recipient_StaffID = ps.StaffID
        ORDER BY ma.YearWon DESC, aw.AwardName, m.Title;

    rec cur_awards%ROWTYPE;
    v_recipient_name VARCHAR2(4000);
    v_recipient_type VARCHAR2(10);
BEGIN
    OPEN cur_awards;
    LOOP
        FETCH cur_awards INTO rec;
        EXIT WHEN cur_awards%NOTFOUND;

        IF rec.ActorFirst IS NOT NULL OR rec.ActorLast IS NOT NULL THEN
            v_recipient_name := TRIM(NVL(rec.ActorFirst,'') || ' ' || NVL(rec.ActorLast,''));
            v_recipient_type := 'Actor';
        ELSIF rec.StaffFirst IS NOT NULL OR rec.StaffLast IS NOT NULL THEN
            v_recipient_name := TRIM(NVL(rec.StaffFirst,'') || ' ' || NVL(rec.StaffLast,''));
            v_recipient_type := 'Staff';
        ELSE
            v_recipient_name := '—';
            v_recipient_type := '—';
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            rec.YearWon || ' | ' ||
            NVL(rec.AwardName, '—') || ' | ' ||
            NVL(rec.MovieTitle, '—') || ' | ' ||
            v_recipient_name || CASE WHEN v_recipient_type <> '—' THEN ' (' || v_recipient_type || ')' ELSE '' END || ' | ' ||
            'Win: ' || NVL(rec.DidWin, 'N')
        );
    END LOOP;
    CLOSE cur_awards;
END;
/

--CURSOR for each genre of the top 3 films
DECLARE
    v_top_n CONSTANT PLS_INTEGER := 3;

    CURSOR cur_genres IS
        SELECT GenreID, GenreName FROM Genre ORDER BY GenreName;

    rec_genre cur_genres%ROWTYPE;

    CURSOR cur_top_movies(p_genreid NUMBER) IS
        SELECT m.MovieID, m.Title, ROUND(AVG(r.RatingScore),2) AS AvgRating, COUNT(r.ReviewID) AS ReviewCount
        FROM Movie_Genre mg
        JOIN Movie m ON mg.MovieID = m.MovieID
        LEFT JOIN Review r ON m.MovieID = r.MovieID
        WHERE mg.GenreID = p_genreid
        GROUP BY m.MovieID, m.Title
        ORDER BY AVG(r.RatingScore) DESC NULLS LAST, COUNT(r.ReviewID) DESC, m.Title;

    rec_movie cur_top_movies%ROWTYPE;
    v_counter PLS_INTEGER;
BEGIN
    OPEN cur_genres;
    LOOP
        FETCH cur_genres INTO rec_genre;
        EXIT WHEN cur_genres%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Genre: ' || rec_genre.GenreName);

        OPEN cur_top_movies(rec_genre.GenreID);
        v_counter := 0;
        LOOP
            FETCH cur_top_movies INTO rec_movie;
            EXIT WHEN cur_top_movies%NOTFOUND OR v_counter >= v_top_n;
            v_counter := v_counter + 1;
            DBMS_OUTPUT.PUT_LINE('  '||v_counter||'. '||rec_movie.Title||' | AvgRating: '||NVL(TO_CHAR(rec_movie.AvgRating),'N/A')||' | Reviews: '||rec_movie.ReviewCount);
        END LOOP;
        CLOSE cur_top_movies;

        IF v_counter = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  (no movies for this genre)');
        END IF;

        DBMS_OUTPUT.PUT_LINE(''); 
    END LOOP;
    CLOSE cur_genres;
END;
/

--CURSOR: How many films has the staff participated in and his unique roles
DECLARE
    CURSOR cur_staff IS
        SELECT StaffID, FirstName, LastName FROM Production_Staff ORDER BY LastName, FirstName;

    rec_staff cur_staff%ROWTYPE;
    v_movie_count NUMBER;
    v_role_count  NUMBER;
BEGIN
    OPEN cur_staff;
    LOOP
        FETCH cur_staff INTO rec_staff;
        EXIT WHEN cur_staff%NOTFOUND;

        SELECT COUNT(DISTINCT MovieID) INTO v_movie_count FROM Movie_Crew WHERE StaffID = rec_staff.StaffID;
        SELECT COUNT(DISTINCT RoleID)  INTO v_role_count  FROM Movie_Crew WHERE StaffID = rec_staff.StaffID;

        DBMS_OUTPUT.PUT_LINE(rec_staff.FirstName || ' ' || rec_staff.LastName || ' | Movies: ' || NVL(TO_CHAR(v_movie_count),'0') || ' | UniqueRoles: ' || NVL(TO_CHAR(v_role_count),'0'));
    END LOOP;
    CLOSE cur_staff;
END;
/

--prints, for each of the last 5 years, which studios released movies and how many
DECLARE
    v_year_from PLS_INTEGER := EXTRACT(YEAR FROM SYSDATE) - 4; 
    v_year_to   PLS_INTEGER := EXTRACT(YEAR FROM SYSDATE);
    CURSOR cur_years IS
        SELECT DISTINCT LEVEL + v_year_from - 1 AS yr FROM dual CONNECT BY LEVEL <= (v_year_to - v_year_from + 1);

    rec_year cur_years%ROWTYPE;
    CURSOR cur_studios(p_year NUMBER) IS
        SELECT s.StudioID, s.StudioName, COUNT(ms.MovieID) AS MovieCount
        FROM Movie_Studio ms
        JOIN Movie m ON ms.MovieID = m.MovieID
        JOIN Studio s ON ms.StudioID = s.StudioID
        WHERE EXTRACT(YEAR FROM m.ReleaseDate) = p_year
        GROUP BY s.StudioID, s.StudioName
        ORDER BY COUNT(ms.MovieID) DESC, s.StudioName;
    
    rec_studio cur_studios%ROWTYPE;
BEGIN
    OPEN cur_years;
    LOOP
        FETCH cur_years INTO rec_year;
        EXIT WHEN cur_years%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Year: ' || rec_year.yr);

        OPEN cur_studios(rec_year.yr);
        LOOP
            FETCH cur_studios INTO rec_studio;
            EXIT WHEN cur_studios%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('  ' || rec_studio.StudioName || ' | Movies: ' || rec_studio.MovieCount);
        END LOOP;
        CLOSE cur_studios;
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    CLOSE cur_years;
END;
/

--CURSOR for each actor displays the top K co-actors with whom he has acted most often (based on shared MovieIDs).
DECLARE
    v_top_k CONSTANT PLS_INTEGER := 5;

    CURSOR cur_actors IS
        SELECT ActorID, FirstName, LastName FROM Actor ORDER BY LastName, FirstName;

    rec_actor cur_actors%ROWTYPE;

    CURSOR cur_coactors(p_actorid NUMBER) IS
        SELECT co.ActorID, co.FirstName, co.LastName, COUNT(*) AS TogetherCount
        FROM Movie_Cast mc1
        JOIN Movie_Cast mc2 ON mc1.MovieID = mc2.MovieID AND mc2.ActorID <> mc1.ActorID
        JOIN Actor co ON mc2.ActorID = co.ActorID
        WHERE mc1.ActorID = p_actorid
        GROUP BY co.ActorID, co.FirstName, co.LastName
        ORDER BY COUNT(*) DESC, co.LastName, co.FirstName;

    rec_coactor cur_coactors%ROWTYPE;
    v_counter PLS_INTEGER;
BEGIN
    OPEN cur_actors;
    LOOP
        FETCH cur_actors INTO rec_actor;
        EXIT WHEN cur_actors%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Actor: ' || rec_actor.FirstName || ' ' || rec_actor.LastName);

        OPEN cur_coactors(rec_actor.ActorID);
        v_counter := 0;
        LOOP
            FETCH cur_coactors INTO rec_coactor;
            EXIT WHEN cur_coactors%NOTFOUND OR v_counter >= v_top_k;
            v_counter := v_counter + 1;
            DBMS_OUTPUT.PUT_LINE('  ' || v_counter || '. ' || rec_coactor.FirstName || ' ' || rec_coactor.LastName || ' | Together: ' || rec_coactor.TogetherCount);
        END LOOP;
        CLOSE cur_coactors;

        IF v_counter = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  (no co-actors found)');
        END IF;

        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    CLOSE cur_actors;
END;
/

--CURSOR for each movie displays a list of languages ​​(via nested cursor) and the total number of languages
DECLARE
    CURSOR cur_movies IS
        SELECT MovieID, Title FROM Movie ORDER BY ReleaseDate DESC NULLS LAST, Title;

    rec_movie cur_movies%ROWTYPE;

    CURSOR cur_languages(p_movieid NUMBER) IS
        SELECT l.LanguageName
        FROM Movie_Language ml
        JOIN Language l ON ml.LanguageID = l.LanguageID
        WHERE ml.MovieID = p_movieid
        ORDER BY l.LanguageName;

    rec_lang cur_languages%ROWTYPE;
    v_count PLS_INTEGER;
BEGIN
    OPEN cur_movies;
    LOOP
        FETCH cur_movies INTO rec_movie;
        EXIT WHEN cur_movies%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Movie: ' || NVL(rec_movie.Title,'—'));

        OPEN cur_languages(rec_movie.MovieID);
        v_count := 0;
        LOOP
            FETCH cur_languages INTO rec_lang;
            EXIT WHEN cur_languages%NOTFOUND;
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('  - ' || rec_lang.LanguageName);
        END LOOP;
        CLOSE cur_languages;

        DBMS_OUTPUT.PUT_LINE('  Total languages: ' || v_count);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    CLOSE cur_movies;
END;
/