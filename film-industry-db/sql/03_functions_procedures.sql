-----------FUNCTIONS|PROCEDURES-----------------
/*FN_MOVIE_AVG_RATING
Used anywhere you need to display a movie’s average rating (movie page, admin dashboards, ranking lists).*/

CREATE OR REPLACE FUNCTION fn_movie_avg_rating (
    p_movie_id IN Movie.MovieID%TYPE
) RETURN NUMBER
IS
    v_avg_rating NUMBER;
BEGIN
    SELECT ROUND(AVG(r.RatingScore),2)
    INTO   v_avg_rating
    FROM   Review r
    WHERE  r.MovieID = p_movie_id;

    -- If no reviews, AVG returns NULL → function returns NULL
    RETURN v_avg_rating;
END fn_movie_avg_rating;
/

/*FN_ACTOR_AVG_MOVIE_RATING
Real-life meaning:
KPI for casting / marketing: “On average, movies with this actor get X/10 from users.”
*/

CREATE OR REPLACE FUNCTION fn_actor_avg_movie_rating (
    p_actor_id IN Actor.ActorID%TYPE
) RETURN NUMBER
IS
    v_avg_rating NUMBER;
BEGIN
    SELECT AVG(r.RatingScore)
    INTO   v_avg_rating
    FROM   Movie_Cast mc
           JOIN Review r
             ON r.MovieID = mc.MovieID
    WHERE  mc.ActorID = p_actor_id;

    RETURN v_avg_rating;  
END fn_actor_avg_movie_rating;
/

--3) FN_DIRECTOR_AWARD_RATE

CREATE OR REPLACE FUNCTION fn_director_award_rate (
    p_staff_id IN Production_Staff.StaffID%TYPE
) RETURN NUMBER
IS
    v_rate NUMBER;
BEGIN
    SELECT ( COUNT(DISTINCT CASE
                               WHEN ma.DidWin = 'Y' THEN m.MovieID
                            END) * 1.0 )
           / NULLIF(COUNT(DISTINCT m.MovieID), 0)
    INTO   v_rate
    FROM   Movie_Crew mc
           JOIN Role r
             ON r.RoleID = mc.RoleID
           JOIN Movie m
             ON m.MovieID = mc.MovieID
           LEFT JOIN Movie_Awards ma
             ON ma.MovieID = m.MovieID
    WHERE  mc.StaffID = p_staff_id
       AND r.RoleName = 'Director';
    RETURN v_rate;
END fn_director_award_rate;
/


/*PR_GET_TOP_MOVIES_BY_GENRE
Real-life meaning:
Used for a “Top movies in genre X” page or report, but only for movies with enough reviews (to avoid noisy scores).
*/
CREATE OR REPLACE PROCEDURE pr_get_top_movies_by_genre (
    p_genre_name  IN Genre.GenreName%TYPE,
    p_min_reviews IN NUMBER DEFAULT 10,
    p_limit       IN NUMBER DEFAULT 10
)
IS
    v_counter PLS_INTEGER := 0;
BEGIN
    FOR rec IN (
        SELECT vg.MovieID                    AS movie_id,
               vg.MovieTitle                 AS title,
               ROUND(AVG(r.RatingScore), 2)  AS avg_rating,
               COUNT(r.ReviewID)             AS review_count
        FROM   vw_movie_genres vg
               LEFT JOIN Review r ON r.MovieID = vg.MovieID
        WHERE  vg.GenreName = p_genre_name
        GROUP BY vg.MovieID, vg.MovieTitle
        HAVING COUNT(r.ReviewID) >= p_min_reviews
        ORDER BY AVG(r.RatingScore) DESC,
                 COUNT(r.ReviewID) DESC
    )
    LOOP
        v_counter := v_counter + 1;
        EXIT WHEN v_counter > p_limit;

        DBMS_OUTPUT.PUT_LINE(
            v_counter || '. ' || rec.title ||
            ' | AvgRating=' || NVL(TO_CHAR(rec.avg_rating), 'N/A') ||
            ' | Reviews='   || rec.review_count
        );
    END LOOP;
END pr_get_top_movies_by_genre;
/


--PR_GET_USER_RECOMMENDATIONS
CREATE OR REPLACE PROCEDURE pr_get_user_recommendations (
    p_user_id IN "User".UserID%TYPE,
    p_limit   IN NUMBER DEFAULT 10
)
IS
    CURSOR c_reco IS
        WITH user_top_genres AS (
            SELECT g.GenreID
            FROM   Review r
                   JOIN Movie_Genre mg ON mg.MovieID = r.MovieID
                   JOIN Genre g       ON g.GenreID  = mg.GenreID
            WHERE  r.UserID      = p_user_id
               AND r.RatingScore >= 8
            GROUP BY g.GenreID
            ORDER BY AVG(r.RatingScore) DESC,
                     COUNT(*) DESC
            FETCH FIRST 3 ROWS ONLY
        ),
        candidate_movies AS (
            SELECT DISTINCT m.MovieID
            FROM   Movie m
                   JOIN Movie_Genre mg ON mg.MovieID = m.MovieID
            WHERE  mg.GenreID IN (SELECT GenreID FROM user_top_genres)
               AND NOT EXISTS (
                   SELECT 1
                   FROM   Review r2
                   WHERE  r2.MovieID = m.MovieID
                      AND r2.UserID  = p_user_id
               )
        )
        SELECT m.MovieID AS movie_id,
               m.Title   AS title,
               ROUND(AVG(r.RatingScore), 2) AS avg_rating,
               COUNT(r.ReviewID)            AS review_count
        FROM   candidate_movies cm
               JOIN Movie m     ON m.MovieID   = cm.MovieID
               LEFT JOIN Review r ON r.MovieID = m.MovieID
        GROUP BY m.MovieID, m.Title
        ORDER BY avg_rating DESC, review_count DESC;

    v_counter PLS_INTEGER := 0;
BEGIN
    FOR rec IN c_reco LOOP
        v_counter := v_counter + 1;
        EXIT WHEN v_counter > p_limit;

        DBMS_OUTPUT.PUT_LINE(
              v_counter || '. ' || rec.title
           || ' | AvgRating=' || NVL(TO_CHAR(rec.avg_rating), 'N/A')
           || ' | Reviews='   || rec.review_count
        );
    END LOOP;
END pr_get_user_recommendations;
/


--PR_ADD_REVIEW_SAFE
CREATE OR REPLACE PROCEDURE pr_add_review_safe (
    p_user_id      IN "User".UserID%TYPE,
    p_movie_id     IN Movie.MovieID%TYPE,
    p_rating_score IN Review.RatingScore%TYPE,
    p_review_text  IN Review.ReviewText%TYPE
)
IS
BEGIN
    INSERT INTO Review (MovieID, UserID, RatingScore, ReviewText)
    VALUES (p_movie_id,
            p_user_id,
            p_rating_score,
            p_review_text);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        -- User already has a review for this (MovieID, UserID)
        RAISE_APPLICATION_ERROR(
            -20001,
            'This user has already reviewed the selected movie.'
        );
END pr_add_review_safe;
/

---------------------------------------------------------------------------------
/*pr_actor_filmography_report
What it does:
Displays an actor's filmography: films + characters + release date.
*/
CREATE OR REPLACE PROCEDURE pr_actor_filmography_report (
    p_actor_id IN Actor.ActorID%TYPE
)
IS
    CURSOR c_filmography IS
        SELECT m.MovieID,
               m.Title,
               m.ReleaseDate,
               c.CharacterName
        FROM   Movie_Cast mc
               JOIN Movie m
                 ON m.MovieID = mc.MovieID
               JOIN Character c
                 ON c.CharacterID = mc.CharacterID
        WHERE  mc.ActorID = p_actor_id
        ORDER  BY m.ReleaseDate NULLS LAST;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Filmography for actor ID = ' || p_actor_id);

    FOR rec IN c_filmography LOOP   
        DBMS_OUTPUT.PUT_LINE(
            'MovieID=' || rec.MovieID ||
            ' | Title=' || rec.Title ||
            ' | ReleaseDate=' || TO_CHAR(rec.ReleaseDate, 'YYYY-MM-DD') ||
            ' | Character=' || rec.CharacterName
        );
    END LOOP;
END pr_actor_filmography_report;
/
-- Execution test block
BEGIN
    pr_actor_filmography_report( p_actor_id => 1001 );
END;
/

-----------------------------------------------------------------------------
--prints per-year statistics for a given genre: how many movies were released each year and what their average rating was
CREATE OR REPLACE PROCEDURE pr_genre_yearly_trends (
    p_genre_name IN Genre.GenreName%TYPE
)
IS
    CURSOR c_trends IS
        SELECT EXTRACT(YEAR FROM m.ReleaseDate) AS release_year,
               COUNT(DISTINCT m.MovieID)        AS movie_count,
               ROUND(AVG(r.RatingScore), 2)     AS avg_rating
        FROM   vw_movie_genres vg
               JOIN Movie m    ON m.MovieID    = vg.MovieID
               LEFT JOIN Review r ON r.MovieID = vg.MovieID
        WHERE  vg.GenreName = p_genre_name
        GROUP BY EXTRACT(YEAR FROM m.ReleaseDate)
        ORDER BY release_year;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Yearly trends for genre = ' || p_genre_name);

    FOR rec IN c_trends LOOP
        DBMS_OUTPUT.PUT_LINE(
              'Year='      || rec.release_year
           || ' | Movies=' || rec.movie_count
           || ' | AvgRating=' || NVL(TO_CHAR(rec.avg_rating), 'N/A')
        );
    END LOOP;
END pr_genre_yearly_trends;
/

-----------------------------------------------------
/*returns a verdict for each movie based on its reviews and awards:
If the movie has avg rating ≥ 8 or any awards → HIT
If the avg rating is < 4 → FLOP
Otherwise → AVERAGE*/
CREATE OR REPLACE FUNCTION is_movie_hit_or_flop(p_movie_id IN NUMBER) 
RETURN VARCHAR2 IS
    v_avg_score NUMBER;
    v_award_count NUMBER;
BEGIN
    SELECT AVG(RatingScore) INTO v_avg_score FROM Review WHERE MovieID = p_movie_id;
    SELECT COUNT(*) INTO v_award_count FROM Movie_Awards WHERE MovieID = p_movie_id;
    
    IF v_avg_score >= 8.0 OR v_award_count > 0 THEN
        RETURN 'HIT';
    ELSIF v_avg_score < 4.0 THEN
        RETURN 'FLOP';
    ELSE
        RETURN 'AVERAGE';
    END IF;
END;
/
-- Execution test query
-- SELECT Title, is_movie_hit_or_flop(MovieID) as Verdict FROM Movie;