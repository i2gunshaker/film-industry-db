--Views for Bridge Tables

CREATE OR REPLACE VIEW vw_movie_genres AS
SELECT
    m.MovieID      AS MovieID,
    m.Title        AS MovieTitle,
    g.GenreID      AS GenreID,
    g.GenreName    AS GenreName
FROM Movie m
JOIN Movie_Genre mg ON mg.MovieID = m.MovieID
JOIN Genre g        ON g.GenreID  = mg.GenreID;


CREATE OR REPLACE VIEW vw_movie_studios AS
SELECT
    m.MovieID               AS MovieID,
    m.Title                 AS MovieTitle,
    s.StudioID              AS StudioID,
    s.StudioName            AS StudioName,
    s.YearFounded           AS StudioYearFounded,
    s.HeadquartersCountryID AS HeadquartersCountryID
FROM Movie m
JOIN Movie_Studio ms ON ms.MovieID = m.MovieID
JOIN Studio s        ON s.StudioID = ms.StudioID;


CREATE OR REPLACE VIEW vw_movie_countries AS
SELECT
    m.MovieID     AS MovieID,
    m.Title       AS MovieTitle,
    c.CountryID   AS CountryID,
    c.CountryName AS CountryName,
    c.CountryCode AS CountryCode
FROM Movie m
JOIN Movie_Country mc ON mc.MovieID   = m.MovieID
JOIN Country c        ON c.CountryID  = mc.CountryID;


CREATE OR REPLACE VIEW vw_movie_languages AS
SELECT
    m.MovieID      AS MovieID,
    m.Title        AS MovieTitle,
    l.LanguageID   AS LanguageID,
    l.LanguageName AS LanguageName,
    l.LanguageCode AS LanguageCode
FROM Movie m
JOIN Movie_Language ml ON ml.MovieID   = m.MovieID
JOIN Language l        ON l.LanguageID = ml.LanguageID;


CREATE OR REPLACE VIEW vw_movie_cast AS
SELECT
    m.MovieID       AS MovieID,
    m.Title         AS MovieTitle,
    a.ActorID       AS ActorID,
    a.FirstName     AS ActorFirstName,
    a.LastName      AS ActorLastName,
    c.CharacterID   AS CharacterID,
    c.CharacterName AS CharacterName
FROM Movie m
JOIN Movie_Cast mc ON mc.MovieID    = m.MovieID
JOIN Actor a       ON a.ActorID     = mc.ActorID
JOIN Character c   ON c.CharacterID = mc.CharacterID;


CREATE OR REPLACE VIEW vw_movie_crew AS
SELECT
    m.MovieID       AS MovieID,
    m.Title         AS MovieTitle,
    ps.StaffID      AS StaffID,
    ps.FirstName    AS StaffFirstName,
    ps.LastName     AS StaffLastName,
    r.RoleID        AS RoleID,
    r.RoleName      AS RoleName,
    r.RoleType      AS RoleType
FROM Movie m
JOIN Movie_Crew mc      ON mc.MovieID  = m.MovieID
JOIN Production_Staff ps ON ps.StaffID = mc.StaffID
JOIN Role r             ON r.RoleID    = mc.RoleID;


CREATE OR REPLACE VIEW vw_movie_awards AS
SELECT
    ma.MovieAwardID        AS MovieAwardID,
    m.MovieID              AS MovieID,
    m.Title                AS MovieTitle,
    aw.AwardID             AS AwardID,
    aw.AwardName           AS AwardName,
    aw.AwardingBody        AS AwardingBody,
    ma.YearWon             AS YearWon,
    ma.DidWin              AS DidWin,
    a.ActorID              AS ActorID,
    a.FirstName            AS ActorFirstName,
    a.LastName             AS ActorLastName,
    ps.StaffID             AS StaffID,
    ps.FirstName           AS StaffFirstName,
    ps.LastName            AS StaffLastName
FROM Movie_Awards ma
JOIN Movie m           ON m.MovieID   = ma.MovieID
JOIN Award aw          ON aw.AwardID  = ma.AwardID
LEFT JOIN Actor a      ON a.ActorID   = ma.Recipient_ActorID
LEFT JOIN Production_Staff ps ON ps.StaffID = ma.Recipient_StaffID;