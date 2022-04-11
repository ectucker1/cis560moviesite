
--Setup
IF SCHEMA_ID(N'MovieDatabase') IS NULL
   EXEC(N'CREATE SCHEMA [MovieDatabase];');
GO

DROP TABLE IF EXISTS MovieDatabase.Users
DROP TABLE IF EXISTS MovieDatabase.Movies
DROP TABLE IF EXISTS MovieDatabase.Reviews
DROP TABLE IF EXISTS MovieDatabase.Watchlists
DROP TABLE IF EXISTS MovieDatabase.Genres
DROP TABLE IF EXISTS MovieDatabase.MovieGenres

--TABLE DECLARATIONS
CREATE TABLE MovieDatabase.Users
(
	UserID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Email NVARCHAR(128) NOT NULL UNIQUE,
	DisplayName NVARCHAR(64) NOT NULL,
	PasswordHash INT NOT NULL,
	IsAdmin INT NOT NULL CHECK(IsAdmin BETWEEN 0 AND 1) DEFAULT(0)
);

CREATE TABLE MovieDatabase.Movies
(
	MovieID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Title NVARCHAR(128) NOT NULL,
	[Length] INT NOT NULL,                   
	[Year] INT NOT NULL,
	IMDBID INT NOT NULL,                                                  --not sure what the NUL we have in the database model means
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
	[Text] TEXT,                          
	PostedOn DATETIMEOFFSET NOT NULL DEFAULT(SYSDATETIMEOFFSET()),
	IsDeleted INT NOT NULL CHECK(IsDeleted BETWEEN 0 AND 1) DEFAULT(0)
);

CREATE TABLE MovieDatabase.Watchlists
(
	WatchlistID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	UserID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Users(UserID),
	MovieID INT NOT NULL FOREIGN KEY REFERENCES MovieDatabase.Movies(MovieID),  --should have multiple movies on a watchlist, how does that work with our initial design?
	WatchedOn DATETIMEOFFSET,
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


--AGGREGATING QUERIES
GO
CREATE OR ALTER PROCEDURE MovieDatabase.FilterByGenre
   @GenreId INT                                        --Do we want to be able to search for multiple genres at a time? If so can we put those values in multiple declared variables?
AS
-- Show all movies with a selected combination of genres.         
SELECT M.MovieID, M.Title, M.[Year], M.[Length]
FROM MovieDatabase.Movies M
	INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
	INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
		AND G.GenreID = @GenreID
GROUP BY M.MovieID, M.Title, M.[Year], M.[Length]
ORDER BY M.Title ASC
GO

CREATE OR ALTER PROCEDURE MovieDatabase.GetReviews
	@MovieID INT
AS
--Search for/return all the reviews for a given movie. 
SELECT R.ReviewID, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn
FROM MovieDatabase.Reviews R
	INNER JOIN MovieDatabase.Movies M ON M.MovieID = R.MovieID
		AND R.MovieID = @MovieID
GROUP BY R.ReviewID, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn
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
GROUP BY W.WatchListID, M.Title, W.WatchedOn, M.[Year], M.[Length]
ORDER BY M.Title ASC
GO

CREATE OR ALTER PROCEDURE MovieDatabase.GetUnverifiedMovies
AS
--Find all movies that have not been approved and information about the user that submitted it.
SELECT M.MovieID, M.Title, U.UserID, U.DisplayName, M.CreatedOn 
FROM MovieDatabase.Movies M 
	INNER JOIN MovieDatabase.Users U ON U.UserID = M.CreatedByUserID
WHERE M.VerifiedOn IS NULL
GROUP BY M.MovieID, M.Title, U.UserID, U.DisplayName, M.CreatedOn
ORDER BY M.CreatedOn ASC
GO


--INSERT STORED PROCEDURES

--Create new Movie
CREATE OR ALTER PROCEDURE MovieDatabase.CreateMovie
	@Title NVARCHAR(128), @Length INT, @Year INT, @UserID INT
AS
INSERT MovieDatabase.Movies(Title, [Length], [Year], CreatedByUserID)
VALUES(@Title, @Length, @Year, @UserID);
GO

--Create new User
CREATE OR ALTER PROCEDURE MovieDatabase.CreateUser
	@Email NVARCHAR(128), @DisplayName NVARCHAR(64)
AS
INSERT MovieDatabase.Users(Email, DisplayName)
VALUES(@Email, @DisplayName);

--Create new Review
CREATE OR ALTER PROCEDURE MovieDatabase.CreateReview
  @UserID INT, @MovieID INT, @Text TEXT, @StarRating INT
AS
INSERT MovieDatabase.Reviews(ReviewingUserID, MovieID, [Text], StarRating)
VALUES(@UserID, @MovieID, @Text, @StarRating)

--Create new Watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.CreateWatchlist
  @UserID INT, @MovieID INT
AS
INSERT MovieDatabase.Watchlists(UserID, MovieID)
VALUES(@UserID, @MovieID)


--UPDATE STORED PROCEDURES

--Update Review
CREATE OR ALTER PROCEDURE MovieDatabase.UpdateReview
  @ReviewID INT, @Text TEXT, @StarRating INT
AS
UPDATE MovieDatabase.Reviews
SET
  [Text] = @Text,
  StarRating = @StarRating
WHERE ReviewID = @ReviewID

--Delete Review
CREATE OR ALTER PROCEDURE MovieDatabase.DeleteReview
  @ReviewID INT
AS
UPDATE MovieDatabase.Reviews
SET
  IsDeleted = 1
WHERE ReviewID = @ReviewID

--Verify Movie
CREATE OR ALTER PROCEDURE MovieDatabase.VerifyMovie
  @MovieID INT
AS
UPDATE MovieDatabase.Movies
SET
  VerifiedOn = SYSDATETIMEOFFSET()
WHERE MovieID = @MovieID

--Update WatchList
CREATE OR ALTER PROCEDURE MovieDatabase.UpdateWatchlist
  @WatchedOn DATETIMEOFFSET
AS
UPDATE MovieDatabase.Watchlists
SET
  WatchedOn = @WatchedOn
WHERE WatchlistID = @WatchlistID

--Delete Watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.DeleteWatchlist
  @WatchlistID INT
AS
UPDATE MovieDatabase.Watchlists
SET
  IsDeleted = 1
WHERE WatchlistID = @WatchlistID
