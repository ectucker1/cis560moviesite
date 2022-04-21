const bodyParser = require('body-parser')
const app = require('express')()
const sql = require('mssql')
const jwt = require('jsonwebtoken');

const sqlConfig = {
  user: process.env.SQL_SERVER_USER,
  password: process.env.SQL_SERVER_PASSWORD,
  database: process.env.SQL_SERVER_DATABASE,
  server: process.env.SQL_SERVER_URL,
  port: process.env.SQL_SERVER_PORT,
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  },
  options: {
    encrypt: false, // for azure
    trustServerCertificate: false // change to true for local dev / self-signed certs
  }
}

const jwtKey = process.env.JWT_KEY
const jwtDuration = '3 days'


app.use(bodyParser.json())

app.all('/getJSON', (req, res) => {
  res.json({ data: 'data' })
})

app.all('/movies', async (req, res) => {
	
await sql.connect(sqlConfig);
const createResult = await sql.query`
--Setup
IF SCHEMA_ID(N'MovieDatabase') IS NULL
   EXEC(N'CREATE SCHEMA [MovieDatabase];');
GO

DROP TABLE IF EXISTS MovieDatabase.MovieGenres;
DROP TABLE IF EXISTS MovieDatabase.Genres;
DROP TABLE IF EXISTS MovieDatabase.Watchlists;
DROP TABLE IF EXISTS MovieDatabase.Reviews;
DROP TABLE IF EXISTS MovieDatabase.Movies;
DROP TABLE IF EXISTS MovieDatabase.Users;

--TABLE DECLARATIONS
CREATE TABLE MovieDatabase.Users
(
	UserID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Email NVARCHAR(128) NOT NULL UNIQUE,
	DisplayName NVARCHAR(64) NOT NULL,
	PasswordHash NVARCHAR(128) NOT NULL,
	IsAdmin INT NOT NULL CHECK(IsAdmin BETWEEN 0 AND 1) DEFAULT(0)
);

CREATE TABLE MovieDatabase.Movies
(
	MovieID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Title NVARCHAR(128) NOT NULL,
	[Length] INT NOT NULL,
	[Year] INT NOT NULL,
	IMDBID INT DEFAULT(NULL),
	VerifiedOn DATETIMEOFFSET DEFAULT(NULL),
	IsDeleted INT NOT NULL CHECK(IsDeleted BETWEEN 0 AND 1) DEFAULT(0),
	CreatedOn DATETIMEOFFSET NOT NULL DEFAULT(SYSDATETIMEOFFSET()),
	CreatedByUserID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Users(UserID)

	UNIQUE([Year], [Title])
);

CREATE TABLE MovieDatabase.Reviews
(
	ReviewID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	ReviewingUserID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Users(UserID),
	MovieID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Movies(MovieID),
	StarRating INT NOT NULL CHECK(StarRating BETWEEN 0 AND 5),
	[Text] NVARCHAR(2048),
	PostedOn DATETIMEOFFSET NOT NULL DEFAULT(SYSDATETIMEOFFSET()),
	IsDeleted INT NOT NULL CHECK(IsDeleted BETWEEN 0 AND 1) DEFAULT(0)
);

CREATE TABLE MovieDatabase.Watchlists
(
	WatchlistID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	UserID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Users(UserID),
	MovieID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Movies(MovieID),
	WatchedOn DATETIMEOFFSET DEFAULT(NULL),
	IsDeleted INT NOT NULL CHECK(IsDeleted BETWEEN 0 AND 1) DEFAULT(0)

	UNIQUE(UserID, MovieID)
);

CREATE TABLE MovieDatabase.Genres
(
	GenreID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] NVARCHAR(64) NOT NULL UNIQUE
);

CREATE TABLE MovieDatabase.MovieGenres
(
	MovieGenreID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	MovieID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Movies(MovieID),
	GenreID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Genres(GenreID)

	UNIQUE(MovieID, GenreID)
);


--QUERIES
GO
CREATE OR ALTER PROCEDURE MovieDatabase.SearchForMovie        --Function to possibly replace FilterByGenre
   @SortBy INT, @SortOrder INT, @Title NVARCHAR(128), @GenreId INT
AS
-- Search for movies with the given filters
SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating)
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
		AND G.GenreID = @GenreID
    AND M.Title = @Title                    --not sure how to incorportate IF for title if they left title field blank
WHERE M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
--IF @SortBy = 0
--  IF @SortOrder = 0
--    ORDER BY M.[Year] ASC
--  ELSE
--    ORDER BY M.[Year] DESC
--ELSE
--  IF @SortOrder = 0
--    ORDER BY AVG(R.StarRating) ASC
--  ELSE
--    ORDER BY AVG(R.StarRating) DESC
GO

GO
CREATE OR ALTER PROCEDURE MovieDatabase.FilterByGenre --AGGREGATING QUERY
   @GenreId INT
AS
-- Show all movies with a selected combination of genres.         
SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
		AND G.GenreID = @GenreID
WHERE M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
ORDER BY AVG(R.StarRating) DESC , M.Title ASC 
GO

CREATE OR ALTER PROCEDURE MovieDatabase.GetReviews
	@MovieID INT
AS
--Search for/return all the reviews for a given movie.
SELECT R.ReviewID, U.DisplayName, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn
FROM MovieDatabase.Reviews R
  INNER JOIN MovieDatabase.Users U ON U.UserID = R.ReviewingUserID
	INNER JOIN MovieDatabase.Movies M ON M.MovieID = R.MovieID
		AND R.MovieID = @MovieID
WHERE M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY R.ReviewID, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn, U.DisplayName
ORDER BY R.PostedOn DESC
GO

CREATE OR ALTER PROCEDURE MovieDatabase.GetWatchlist
	@UserID INT
AS
--Find all movies on a user’s watchlist
SELECT W.WatchListID, M.Title, W.WatchedOn, M.[Year], M.[Length]
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.Watchlists W ON W.MovieID = M.MovieID
	INNER JOIN MovieDatabase.Users U ON U.UserID = W.UserID
		AND U.UserID = @UserID
WHERE M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY W.WatchListID, M.Title, W.WatchedOn, M.[Year], M.[Length]
ORDER BY M.Title ASC
GO

CREATE OR ALTER PROCEDURE MovieDatabase.GetUnverifiedMovies --AGGREGATING QUERY
AS
--Find all movies that have not been approved and information about the user that submitted it.
SELECT M.MovieID, M.Title, M.[Year], M.[Length], G.[Name], U.UserID, U.DisplayName, M.CreatedOn, COUNT(DISTINCT M.MovieID) AS NumberOfUnverified
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.Users U ON U.UserID = M.CreatedByUserID
  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
WHERE M.VerifiedOn IS NULL
  AND M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY M.MovieID, M.Title, U.UserID, U.DisplayName, M.CreatedOn, M.[Year], M.[Length], G.[Name]
ORDER BY M.CreatedOn ASC
GO

--Returns data for one MovieID
CREATE OR ALTER PROCEDURE MovieDatabase.GetMovieData --AGGREGATING QUERY
  @MovieID INT
AS
SELECT M.Title, M.[Year], M.[Length], G.[Name], AVG(R.StarRating) AS StarRating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
FROM MovieDatabase.Movies M
  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
WHERE M.MovieID = @MovieID
GROUP BY M.Title, M.[Year], M.[Length], G.[Name]
GO

--Function to check login information
CREATE OR ALTER PROCEDURE MovieDatabase.CheckLogin
  @Email NVARCHAR(128), @PasswordHash NVARCHAR(128)
AS
IF NOT EXISTS (SELECT U.UserID
FROM MovieDatabase.Users U
  WHERE U.Email = @Email
    AND U.PasswordHash = @PasswordHash
)
SELECT NULL
ELSE
  SELECT U.UserID
  FROM MovieDatabase.Users U
    WHERE U.Email = @Email
      AND U.PasswordHash = @PasswordHash
GO

--Function to get user information
CREATE OR ALTER PROCEDURE MovieDatabase.GetUser
  @UserID INT
AS
IF NOT EXISTS (SELECT U.UserID
FROM MovieDatabase.Users U
  WHERE U.UserID = @UserID
)
SELECT NULL
ELSE
  SELECT U.UserID, U.DisplayName, U.IsAdmin
  FROM MovieDatabase.Users U
    WHERE U.UserID = @UserID
GO

--INSERT STORED PROCEDURES

--Create new Movie
CREATE OR ALTER PROCEDURE MovieDatabase.CreateMovie
	@Title NVARCHAR(128), @Length INT, @Year INT, @UserID INT, @IMDBID INT, @GenreName NVARCHAR(128) --how do we know how many genres we are getting?
AS                                                                                                 --will need to insert into MovieGenre table
INSERT MovieDatabase.Movies(Title, [Length], [Year], CreatedByUserID, IMDBID)
VALUES(@Title, @Length, @Year, @UserID, @IMDBID);
GO

--Create new User
CREATE OR ALTER PROCEDURE MovieDatabase.CreateUser
	@Email NVARCHAR(128), @DisplayName NVARCHAR(64), @PasswordHash NVARCHAR(128)
AS
INSERT MovieDatabase.Users(Email, DisplayName, PasswordHash)
VALUES(@Email, @DisplayName, @PasswordHash);
GO

--Create new Review
CREATE OR ALTER PROCEDURE MovieDatabase.CreateReview
  @UserID INT, @MovieID INT, @Text NVARCHAR(2048), @StarRating INT
AS
INSERT MovieDatabase.Reviews(ReviewingUserID, MovieID, [Text], StarRating)
VALUES(@UserID, @MovieID, @Text, @StarRating)
GO

--Create new Watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.CreateWatchlist
  @UserID INT, @MovieID INT
AS
INSERT MovieDatabase.Watchlists(UserID, MovieID)
VALUES(@UserID, @MovieID)
GO

--UPDATE STORED PROCEDURES

--Update Review
CREATE OR ALTER PROCEDURE MovieDatabase.UpdateReview
  @ReviewID INT, @Text NVARCHAR(2048), @StarRating INT
AS
UPDATE MovieDatabase.Reviews
SET
  [Text] = @Text,
  StarRating = @StarRating
WHERE ReviewID = @ReviewID
GO

--Delete Review
CREATE OR ALTER PROCEDURE MovieDatabase.DeleteReview
  @ReviewID INT
AS
UPDATE MovieDatabase.Reviews
SET
  IsDeleted = 1
WHERE ReviewID = @ReviewID
GO

--Verify Movie
CREATE OR ALTER PROCEDURE MovieDatabase.VerifyMovie
  @MovieID INT, @IsAdmin INT
AS
IF @IsAdmin = 1
  UPDATE MovieDatabase.Movies
  SET
    VerifiedOn = SYSDATETIMEOFFSET()
  WHERE MovieID = @MovieID
GO

--Update WatchList
CREATE OR ALTER PROCEDURE MovieDatabase.UpdateWatchlist
  @WatchListID INT, @WatchedOn DATETIMEOFFSET
AS
UPDATE MovieDatabase.Watchlists
SET
  WatchedOn = @WatchedOn
WHERE WatchlistID = @WatchlistID
GO

--Delete Watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.DeleteWatchlist
  @WatchlistID INT
AS
UPDATE MovieDatabase.Watchlists
SET
  IsDeleted = 1
WHERE WatchlistID = @WatchlistID
GO
`
  await sql.connect(sqlConfig)
  const result = await sql.query`SELECT * FROM MovieDatabase.Movies`
  await res.send(result.recordsets[0])
})

app.all('/auth/login', async (req, res) => {
  // Search for user in database
  let pool = await sql.connect(sqlConfig)
  let userID = await pool.request()
    .input('Email', sql.NVarChar(128), req.body.email)
    .input('PasswordHash', sql.NVarChar(128), req.body.password)
    .execute('CheckLogin')

  // User not found; removing
  if (userID == null)
    return res.status(401).end()

  // Create and send token with UserID
  let token = jwt.sign({ id: userID }, jwtKey, { algorithm: 'RS256', expiresIn: jwtDuration })
  res.send({ token: token })
})

app.all('/auth/logout', async (req, res) => {
  // Don't need to handle logout on server - the token is already gone
  res.status(400).send()
})

app.all('/auth/user', async (req, res) => {
  try {
    // Extract UserID from token
    let user = jwt.verify(token, jwtKey);

    // Search for user in database
    let pool = await sql.connect(sqlConfig)
    let userData = await pool.request()
      .input('UserID', sql.Int, user.id)
      .output('UserID', sql.Int)
      .output('DisplayName', sql.Int)
      .output('IsAdmin', sql.Int)
      .execute('GetUser')

    res.send({
      id: userData.UserId,
      name: userData.DisplayName,
      admin: userData.IsAdmin > 0
    })
  } catch(err) {
    res.status(401).end()
  }
})

module.exports = app
