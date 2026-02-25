--SEARCH BUTTON
BEGIN
  CASE :P2_TABLE

    WHEN 'ROLE' THEN
      IF :P2_ROLE_ID IS NULL THEN
        raise_application_error(-20001, 'Role ID is required for search.');
      END IF;

      SELECT RoleName, RoleType
      INTO   :P2_ROLE_NAME, :P2_ROLE_TYPE
      FROM   Role
      WHERE  RoleID = :P2_ROLE_ID;

    WHEN 'ACTOR' THEN
      IF :P2_ACTOR_ID IS NULL THEN
        raise_application_error(-20001, 'Actor ID is required for search.');
      END IF;

      SELECT FirstName, LastName, DateOfBirth
      INTO   :P2_ACTOR_FIRST_NAME,
             :P2_ACTOR_LAST_NAME,
             :P2_ACTOR_DOB
      FROM   Actor
      WHERE  ActorID = :P2_ACTOR_ID;

    WHEN 'PRODUCTION_STAFF' THEN
      IF :P2_STAFF_ID IS NULL THEN
        raise_application_error(-20001, 'Staff ID is required for search.');
      END IF;

      SELECT FirstName, LastName, DateOfBirth
      INTO   :P2_STAFF_FIRST_NAME,
             :P2_STAFF_LAST_NAME,
             :P2_STAFF_DOB
      FROM   Production_Staff
      WHERE  StaffID = :P2_STAFF_ID;

    WHEN 'CHARACTER' THEN
      IF :P2_CHARACTER_ID IS NULL THEN
        raise_application_error(-20001, 'Character ID is required for search.');
      END IF;

      SELECT CharacterName, Description
      INTO   :P2_CHARACTER_NAME,
             :P2_CHARACTER_DESC
      FROM   Character
      WHERE  CharacterID = :P2_CHARACTER_ID;

    WHEN 'COUNTRY' THEN
      IF :P2_COUNTRY_ID IS NULL THEN
        raise_application_error(-20001, 'Country ID is required for search.');
      END IF;

      SELECT CountryName, CountryCode
      INTO   :P2_COUNTRY_NAME,
             :P2_COUNTRY_CODE
      FROM   Country
      WHERE  CountryID = :P2_COUNTRY_ID;

    WHEN 'STUDIO' THEN
      IF :P2_STUDIO_ID IS NULL THEN
        raise_application_error(-20001, 'Studio ID is required for search.');
      END IF;

      SELECT StudioName, HeadquartersCountryID, YearFounded
      INTO   :P2_STUDIO_NAME,
             :P2_HQ_COUNTRY_ID,
             :P2_YEAR_FOUNDED
      FROM   Studio
      WHERE  StudioID = :P2_STUDIO_ID;

    WHEN 'GENRE' THEN
      IF :P2_GENRE_ID IS NULL THEN
        raise_application_error(-20001, 'Genre ID is required for search.');
      END IF;

      SELECT GenreName
      INTO   :P2_GENRE_NAME
      FROM   Genre
      WHERE  GenreID = :P2_GENRE_ID;

    WHEN 'AWARD' THEN
      IF :P2_AWARD_ID IS NULL THEN
        raise_application_error(-20001, 'Award ID is required for search.');
      END IF;

      SELECT AwardName, AwardingBody
      INTO   :P2_AWARD_NAME,
             :P2_AWARDING_BODY
      FROM   Award
      WHERE  AwardID = :P2_AWARD_ID;

    WHEN 'MOVIE' THEN
      IF :P2_MOVIE_ID IS NULL THEN
        raise_application_error(-20001, 'Movie ID is required for search.');
      END IF;

      SELECT Title, ReleaseDate, Synopsis, Duration, MaturityRating
      INTO   :P2_MOVIE_TITLE,
             :P2_MOVIE_RELEASE_DATE,
             :P2_MOVIE_SYNOPSIS,
             :P2_MOVIE_DURATION,
             :P2_MOVIE_RATING
      FROM   Movie
      WHERE  MovieID = :P2_MOVIE_ID;

    WHEN 'USER' THEN  -- no quotes here
      IF :P2_USER_ID IS NULL THEN
        raise_application_error(-20001, 'User ID is required for search.');
      END IF;

      SELECT Username, Email, JoinDate
      INTO   :P2_USERNAME,
             :P2_USER_EMAIL,
             :P2_USER_JOIN_DATE
      FROM   "User"
      WHERE  UserID = :P2_USER_ID;

    -- Everything else (REVIEW, bridge tables, LANGUAGE, etc.)
    -- is handled  by report regions and LOV filters.
    ELSE
      NULL;

  END CASE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    raise_application_error(-20010, 'No row found for this key.');
END;



--INSERT BUTTON
BEGIN
  CASE :P2_TABLE

    WHEN 'ROLE' THEN
      INSERT INTO Role (RoleName, RoleType)
      VALUES (:P2_ROLE_NAME, :P2_ROLE_TYPE)
      RETURNING RoleID INTO :P2_ROLE_ID;

    WHEN 'ACTOR' THEN
      INSERT INTO Actor (FirstName, LastName, DateOfBirth)
      VALUES (:P2_ACTOR_FIRST_NAME, :P2_ACTOR_LAST_NAME, :P2_ACTOR_DOB)
      RETURNING ActorID INTO :P2_ACTOR_ID;

    WHEN 'PRODUCTION_STAFF' THEN
      INSERT INTO Production_Staff (FirstName, LastName, DateOfBirth)
      VALUES (:P2_STAFF_FIRST_NAME, :P2_STAFF_LAST_NAME, :P2_STAFF_DOB)
      RETURNING StaffID INTO :P2_STAFF_ID;

    WHEN 'CHARACTER' THEN
      INSERT INTO Character (CharacterName, Description)
      VALUES (:P2_CHARACTER_NAME, :P2_CHARACTER_DESC)
      RETURNING CharacterID INTO :P2_CHARACTER_ID;

    WHEN 'COUNTRY' THEN
      INSERT INTO Country (CountryName, CountryCode)
      VALUES (:P2_COUNTRY_NAME, :P2_COUNTRY_CODE)
      RETURNING CountryID INTO :P2_COUNTRY_ID;

    WHEN 'STUDIO' THEN
      INSERT INTO Studio (StudioName, HeadquartersCountryID, YearFounded)
      VALUES (:P2_STUDIO_NAME, :P2_HQ_COUNTRY_ID, :P2_YEAR_FOUNDED)
      RETURNING StudioID INTO :P2_STUDIO_ID;

    WHEN 'GENRE' THEN
      INSERT INTO Genre (GenreName)
      VALUES (:P2_GENRE_NAME)
      RETURNING GenreID INTO :P2_GENRE_ID;

    WHEN 'AWARD' THEN
      INSERT INTO Award (AwardName, AwardingBody)
      VALUES (:P2_AWARD_NAME, :P2_AWARDING_BODY)
      RETURNING AwardID INTO :P2_AWARD_ID;

    WHEN 'MOVIE' THEN
      INSERT INTO Movie (
        Title, ReleaseDate, Synopsis, Duration, MaturityRating
      ) VALUES (
        :P2_MOVIE_TITLE,
        :P2_MOVIE_RELEASE_DATE,
        :P2_MOVIE_SYNOPSIS,
        :P2_MOVIE_DURATION,
        :P2_MOVIE_RATING
      )
      RETURNING MovieID INTO :P2_MOVIE_ID;

    WHEN 'USER' THEN
      INSERT INTO "User" (Username, Email, JoinDate)
      VALUES (:P2_USERNAME, :P2_USER_EMAIL, :P2_USER_JOIN_DATE)
      RETURNING UserID INTO :P2_USER_ID;

    WHEN 'REVIEW' THEN
      INSERT INTO Review (MovieID, UserID, RatingScore, ReviewText)
      VALUES (:P2_REVIEW_MOVIE_ID, :P2_REVIEW_USER_ID,
              :P2_REVIEW_SCORE, :P2_REVIEW_TEXT)
      RETURNING ReviewID INTO :P2_REVIEW_ID;

    WHEN 'MOVIE_GENRE' THEN
      INSERT INTO Movie_Genre (MovieID, GenreID)
      VALUES (:P2_MG_MOVIE_ID, :P2_MG_GENRE_ID);

    WHEN 'MOVIE_STUDIO' THEN
      INSERT INTO Movie_Studio (MovieID, StudioID)
      VALUES (:P2_MS_MOVIE_ID, :P2_MS_STUDIO_ID);

    WHEN 'MOVIE_CAST' THEN
      INSERT INTO Movie_Cast (MovieID, ActorID, CharacterID)
      VALUES (:P2_MC_MOVIE_ID, :P2_MC_ACTOR_ID, :P2_MC_CHARACTER_ID);

    WHEN 'MOVIE_CREW' THEN
      INSERT INTO Movie_Crew (MovieID, StaffID, RoleID)
      VALUES (:P2_MCR_MOVIE_ID, :P2_MCR_STAFF_ID, :P2_MCR_ROLE_ID);

    WHEN 'MOVIE_AWARDS' THEN
      INSERT INTO Movie_Awards (
        MovieID, AwardID, Recipient_ActorID, Recipient_StaffID,
        YearWon, DidWin
      ) VALUES (
        :P2_MA_MOVIE_ID, :P2_MA_AWARD_ID,
        :P2_MA_RECIP_ACTOR_ID, :P2_MA_RECIP_STAFF_ID,
        :P2_MA_YEAR_WON, :P2_MA_DID_WIN
      )
      RETURNING MovieAwardID INTO :P2_MA_ID;

    WHEN 'LANGUAGE' THEN
      INSERT INTO Language (LanguageName, LanguageCode)
      VALUES (:P2_LANG_NAME, :P2_LANG_CODE)
      RETURNING LanguageID INTO :P2_LANG_ID;

    WHEN 'MOVIE_COUNTRY' THEN
      INSERT INTO Movie_Country (MovieID, CountryID)
      VALUES (:P2_MC2_MOVIE_ID, :P2_MC2_COUNTRY_ID);

    WHEN 'MOVIE_LANGUAGE' THEN
      INSERT INTO Movie_Language (MovieID, LanguageID)
      VALUES (:P2_ML_MOVIE_ID, :P2_ML_LANGUAGE_ID);

    ELSE
      NULL;
  END CASE;
END;



--DELETE BUTTON
BEGIN
  CASE :P2_TABLE

    WHEN 'ROLE' THEN
      DELETE FROM Role
      WHERE RoleID = :P2_ROLE_ID;

    WHEN 'ACTOR' THEN
      DELETE FROM Actor
      WHERE ActorID = :P2_ACTOR_ID;

    WHEN 'PRODUCTION_STAFF' THEN
      DELETE FROM Production_Staff
      WHERE StaffID = :P2_STAFF_ID;

    WHEN 'CHARACTER' THEN
      DELETE FROM Character
      WHERE CharacterID = :P2_CHARACTER_ID;

    WHEN 'COUNTRY' THEN
      DELETE FROM Country
      WHERE CountryID = :P2_COUNTRY_ID;

    WHEN 'STUDIO' THEN
      DELETE FROM Studio
      WHERE StudioID = :P2_STUDIO_ID;

    WHEN 'GENRE' THEN
      DELETE FROM Genre
      WHERE GenreID = :P2_GENRE_ID;

    WHEN 'AWARD' THEN
      DELETE FROM Award
      WHERE AwardID = :P2_AWARD_ID;

    WHEN 'MOVIE' THEN
      DELETE FROM Movie
      WHERE MovieID = :P2_MOVIE_ID;

    WHEN 'USER' THEN
      DELETE FROM "User"
      WHERE UserID = :P2_USER_ID;

    WHEN 'REVIEW' THEN
      DELETE FROM Review
      WHERE ReviewID = :P2_REVIEW_ID;

    WHEN 'MOVIE_GENRE' THEN
      DELETE FROM Movie_Genre
      WHERE MovieID = :P2_MG_MOVIE_ID
        AND GenreID = :P2_MG_GENRE_ID;

    WHEN 'MOVIE_STUDIO' THEN
      DELETE FROM Movie_Studio
      WHERE MovieID = :P2_MS_MOVIE_ID
        AND StudioID = :P2_MS_STUDIO_ID;

    WHEN 'MOVIE_CAST' THEN
      DELETE FROM Movie_Cast
      WHERE MovieID     = :P2_MC_MOVIE_ID
        AND ActorID     = :P2_MC_ACTOR_ID
        AND CharacterID = :P2_MC_CHARACTER_ID;

    WHEN 'MOVIE_CREW' THEN
      DELETE FROM Movie_Crew
      WHERE MovieID = :P2_MCR_MOVIE_ID
        AND StaffID = :P2_MCR_STAFF_ID
        AND RoleID  = :P2_MCR_ROLE_ID;

    WHEN 'MOVIE_AWARDS' THEN
      DELETE FROM Movie_Awards
      WHERE MovieAwardID = :P2_MA_ID;

    WHEN 'LANGUAGE' THEN
      DELETE FROM Language
      WHERE LanguageID = :P2_LANG_ID;

    WHEN 'MOVIE_COUNTRY' THEN
      DELETE FROM Movie_Country
      WHERE MovieID   = :P2_MC2_MOVIE_ID
        AND CountryID = :P2_MC2_COUNTRY_ID;

    WHEN 'MOVIE_LANGUAGE' THEN
      DELETE FROM Movie_Language
      WHERE MovieID    = :P2_ML_MOVIE_ID
        AND LanguageID = :P2_ML_LANGUAGE_ID;

    ELSE
      NULL;
  END CASE;

  IF SQL%ROWCOUNT = 0 THEN
    raise_application_error(-20020, 'No row deleted - check key values.');
  END IF;
END;
