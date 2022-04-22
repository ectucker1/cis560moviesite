
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
	Poster NVARCHAR(256) NOT NULL DEFAULT(N'/nocover.jpg'),
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


--QUERY STORED PROCEDURES

--Function to possibly replace FilterByGenre, searches for movies with the given filters (AGGREGATING QUERY)
GO
CREATE OR ALTER PROCEDURE MovieDatabase.SearchForMovie        
   @SortBy NVARCHAR(64), @SortOrder NVARCHAR(64), @Title NVARCHAR(128), @GenreID INT
AS
IF @Title IS NOT NULL AND @GenreID IS NOT NULL
  SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
  FROM MovieDatabase.Movies M
	  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
    INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
		  AND G.GenreID = @GenreID
      AND M.Title = @Title
  WHERE M.IsDeleted = 0
    AND VerifiedOn IS NOT NULL
  GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
  ORDER BY (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'ASC' THEN AVG(R.StarRating) END) ASC,
           (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'DESC' THEN AVG(R.StarRating) END) DESC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'ASC' THEN M.[Year] END) ASC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'DESC' THEN M.[Year] END) DESC
ELSE IF @Title IS NOT NULL
  SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
  FROM MovieDatabase.Movies M
	  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
    INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
      AND M.Title = @Title
  WHERE M.IsDeleted = 0
    AND VerifiedOn IS NOT NULL
  GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
  ORDER BY (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'ASC' THEN AVG(R.StarRating) END) ASC,
           (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'DESC' THEN AVG(R.StarRating) END) DESC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'ASC' THEN M.[Year] END) ASC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'DESC' THEN M.[Year] END) DESC
ELSE IF @GenreID IS NOT NULL
  SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
  FROM MovieDatabase.Movies M
	  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
    INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
		  AND G.GenreID = @GenreID
  WHERE M.IsDeleted = 0
    AND VerifiedOn IS NOT NULL
  GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
  ORDER BY (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'ASC' THEN AVG(R.StarRating) END) ASC,
           (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'DESC' THEN AVG(R.StarRating) END) DESC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'ASC' THEN M.[Year] END) ASC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'DESC' THEN M.[Year] END) DESC
GO

/*
-- Show all movies with a selected combination of genres (AGGREGATING QUERY) - POTENTIALLY BEING REPLACED 
CREATE OR ALTER PROCEDURE MovieDatabase.FilterByGenre
   @GenreId INT
AS       
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
GO */

--Search for/return all the reviews for a given movie.
CREATE OR ALTER PROCEDURE MovieDatabase.GetReviews
	@MovieID INT
AS
SELECT R.ReviewID, U.DisplayName, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn
FROM MovieDatabase.Reviews R
  INNER JOIN MovieDatabase.Users U ON U.UserID = R.ReviewingUserID
	INNER JOIN MovieDatabase.Movies M ON M.MovieID = R.MovieID
		AND R.MovieID = @MovieID
WHERE M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
  AND R.IsDeleted = 0
GROUP BY R.ReviewID, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn, U.DisplayName
ORDER BY R.PostedOn DESC
GO

--Find all movies on a user’s watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.GetWatchlist
	@UserID INT
AS
SELECT W.WatchListID, M.Title, W.WatchedOn, M.[Year], M.[Length]
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.Watchlists W ON W.MovieID = M.MovieID
	INNER JOIN MovieDatabase.Users U ON U.UserID = W.UserID
		AND U.UserID = @UserID
WHERE M.IsDeleted = 0
  AND W.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY W.WatchListID, M.Title, W.WatchedOn, M.[Year], M.[Length]
ORDER BY M.Title ASC
GO

--Find all movies that have not been approved and information about the user that submitted it. (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetUnverifiedMovies
AS
SELECT M.MovieID, M.Title, M.[Year], M.[Length], AVG(R.StarRating) AS Rating, G.[Name], U.UserID, U.DisplayName, M.CreatedOn, COUNT(DISTINCT M.MovieID) AS NumberOfUnverified
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.Users U ON U.UserID = M.CreatedByUserID
  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
WHERE M.VerifiedOn IS NULL
  AND M.IsDeleted = 0
  AND VerifiedOn IS NOT NULL
GROUP BY M.MovieID, M.Title, U.UserID, U.DisplayName, M.CreatedOn, M.[Year], M.[Length], G.[Name]
ORDER BY M.CreatedOn ASC
GO

--Get the top 50 users who have done the most reviews (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetTopReviewers
AS
SELECT U.UserID, COUNT(R.ReviewID) OVER(PARTITION BY U.UserID) AS UserReviewCount
FROM MovieDatabase.Users U
  INNER JOIN MovieDatabase.Reviews R ON U.UserID = R.ReviewingUserID
GROUP BY U.UserID
ORDER BY COUNT(R.ReviewID) OVER(PARTITION BY U.UserID) DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
GO

--Returns data for one MovieID (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetMovieData
  @MovieID INT
AS
SELECT M.Title, M.[Year], M.[Length], G.[Name], AVG(R.StarRating) AS StarRating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews, M.Poster
FROM MovieDatabase.Movies M
  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  INNER JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
WHERE M.MovieID = @MovieID
GROUP BY M.Title, M.[Year], M.[Length], G.[Name], M.Poster
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

--Function to get GenreID from GenreName so we can insert into MovieGenre table when creating new movies
CREATE OR ALTER PROCEDURE MovieDatabase.GetGenreID
  @GenreName NVARCHAR(64)
AS
SELECT G.GenreID
FROM MovieDatabase.Genres G
WHERE G.Name = @GenreName
GO

--INSERT STORED PROCEDURES

--Create new Movie
CREATE OR ALTER PROCEDURE MovieDatabase.CreateMovie
	@Title NVARCHAR(128), @Length INT, @Year INT, @UserID INT, @IMDBID INT, @GenreName NVARCHAR(128)
AS                                                                               
INSERT MovieDatabase.Movies(Title, [Length], [Year], CreatedByUserID, IMDBID)
VALUES(@Title, @Length, @Year, @UserID, @IMDBID);
GO

--Insert genre for a movie
CREATE OR ALTER PROCEDURE MovieDatabase.InsertMovieGenre
  @GenreID INT, @MovieID INT
AS
INSERT MovieDatabase.MovieGenres(GenreID, MovieID)
VALUES(@GenreID, @MovieID)
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
