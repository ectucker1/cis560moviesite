
--QUERY/GENERAL STORED PROCEDURES
--Aggregating queries are listed first

--Searches for movies with the given filters (AGGREGATING QUERY)
GO
CREATE OR ALTER PROCEDURE MovieDatabase.SearchForMovie
   @SortBy NVARCHAR(64), @SortOrder NVARCHAR(64), @Title NVARCHAR(128), @GenreID INT, @Page INT
AS
IF @GenreID IS NOT NULL
  SELECT M.MovieID, M.Title, M.[Year], M.[Length], M.Poster, AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
  FROM MovieDatabase.Movies M
	  INNER JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
    INNER JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID AND G.GenreID = @GenreID
    LEFT JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
  WHERE M.IsDeleted = 0
    AND VerifiedOn IS NOT NULL
    AND (CHARINDEX(@Title, M.Title) > 0 OR @Title = N'')
  GROUP BY M.MovieID, M.Title, M.[Year], M.[Length], M.Poster
  ORDER BY (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'ASC' THEN AVG(R.StarRating) END) ASC,
           (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'DESC' THEN AVG(R.StarRating) END) DESC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'ASC' THEN M.[Year] END) ASC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'DESC' THEN M.[Year] END) DESC
  OFFSET (@Page - 1) * 50 ROWS FETCH NEXT 50 ROWS ONLY
ELSE
  SELECT M.MovieID, M.Title, M.[Year], M.[Length], M.Poster, AVG(R.StarRating) AS Rating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews
  FROM MovieDatabase.Movies M
	  LEFT JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
    LEFT JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
    LEFT JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
  WHERE M.IsDeleted = 0
    AND VerifiedOn IS NOT NULL
    AND (CHARINDEX(@Title, M.Title) > 0 OR @Title = N'')
  GROUP BY M.MovieID, M.Title, M.[Year], M.[Length], M.Poster
  ORDER BY (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'ASC' THEN AVG(R.StarRating) END) ASC,
           (CASE WHEN @SortBy = 'Rating' AND @SortOrder = 'DESC' THEN AVG(R.StarRating) END) DESC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'ASC' THEN M.[Year] END) ASC,
           (CASE WHEN @SortBy = 'Year' AND @SortOrder = 'DESC' THEN M.[Year] END) DESC
  OFFSET (@Page - 1) * 50 ROWS FETCH NEXT 50 ROWS ONLY
GO

--Gets the most watchlisted movies (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetMostWatchlisted
AS
SELECT M.MovieID, M.Title, M.[Year], M.Poster, COUNT(DISTINCT W.WatchlistID) AS TimesWatchlisted,
  RANK() OVER(ORDER BY COUNT(DISTINCT W.WatchlistID) DESC) AS WatchlistedRank
FROM MovieDatabase.Movies M
  INNER JOIN MovieDatabase.Watchlists W ON W.MovieID = M.MovieID
WHERE M.IsDeleted = 0
  AND W.IsDeleted = 0
GROUP BY M.MovieID, M.Title, M.[Year], M.Poster
ORDER BY COUNT(DISTINCT W.WatchlistID) DESC, M.Title
GO

--Get the top 50 users who have done the most reviews (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetTopReviewers
AS
SELECT U.UserID, U.DisplayName, COUNT(R.ReviewID) AS UserReviewCount, AVG(R.StarRating) AS AverageRating
FROM MovieDatabase.Users U
  INNER JOIN MovieDatabase.Reviews R ON U.UserID = R.ReviewingUserID
GROUP BY U.UserID, U.DisplayName
ORDER BY COUNT(R.ReviewID) DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
GO

--Returns data for one MovieID (AGGREGATING QUERY)
CREATE OR ALTER PROCEDURE MovieDatabase.GetMovieData
  @MovieID INT
AS
SELECT M.Title, M.[Year], M.[Length], G.[Name], AVG(R.StarRating) AS StarRating, COUNT(DISTINCT R.ReviewID) AS NumberOfReviews, M.Poster
FROM MovieDatabase.Movies M
  LEFT JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  LEFT JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
  LEFT JOIN MovieDatabase.Reviews R ON R.MovieID = M.MovieID
WHERE M.MovieID = @MovieID
GROUP BY M.Title, M.[Year], M.[Length], G.[Name], M.Poster
GO

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

--Get a specific user's review of a specific movie, if it exists
CREATE OR ALTER PROCEDURE MovieDatabase.GetReview
  @UserID INT, @MovieID INT
AS
SELECT R.ReviewID, R.ReviewingUserID, R.StarRating, R.[Text], R.PostedOn
FROM MovieDatabase.Reviews R
WHERE R.MovieID = @MovieID AND R.ReviewingUserID = @UserID
GO

--Find all movies on a user�s watchlist
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

--Find all movies that have not been approved and information about the user that submitted it.
CREATE OR ALTER PROCEDURE MovieDatabase.GetUnverifiedMovies
AS
SELECT M.MovieID, M.Title, M.[Year], M.[Length], G.[Name], U.UserID, U.DisplayName, M.CreatedOn
FROM MovieDatabase.Movies M
	LEFT JOIN MovieDatabase.Users U ON U.UserID = M.CreatedByUserID
  LEFT JOIN MovieDatabase.MovieGenres MG ON MG.MovieID = M.MovieID
  LEFT JOIN MovieDatabase.Genres G ON G.GenreID = MG.GenreID
WHERE M.VerifiedOn IS NULL
  AND M.IsDeleted = 0
GROUP BY M.MovieID, M.Title, U.UserID, U.DisplayName, M.CreatedOn, M.[Year], M.[Length], G.[Name]
ORDER BY M.CreatedOn ASC
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

--Procedure to get GenreID from GenreName so we can insert into MovieGenre table when creating new movies
CREATE OR ALTER PROCEDURE MovieDatabase.GetGenreID
  @GenreName NVARCHAR(64)
AS
SELECT G.GenreID
FROM MovieDatabase.Genres G
WHERE G.Name = @GenreName
GO

--Procedure to get all genres with their names and IDs
CREATE OR ALTER PROCEDURE MovieDatabase.GetGenres
AS
SELECT G.GenreID, G.[Name]
FROM MovieDatabase.Genres G
GO


--INSERT STORED PROCEDURES

--Create new Movie
CREATE OR ALTER PROCEDURE MovieDatabase.CreateMovie
	@Title NVARCHAR(128), @Length INT, @Year INT, @UserID INT, @IMDBID INT, @GenreID INT
AS

DECLARE @MovieTable TABLE(
  MovieID INT
)

INSERT MovieDatabase.Movies(Title, [Length], [Year], CreatedByUserID, IMDBID)
OUTPUT INSERTED.MovieID INTO @MovieTable
VALUES(@Title, @Length, @Year, @UserID, @IMDBID)

INSERT MovieDatabase.MovieGenres(GenreID, MovieID)
SELECT @GenreID, MT.MovieID
FROM @MovieTable MT

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

--Create new Review, or update an existing one
CREATE OR ALTER PROCEDURE MovieDatabase.UpsertReview
  @UserID INT, @MovieID INT, @Text NVARCHAR(2048), @StarRating INT
AS
IF NOT EXISTS
  (
    SELECT * FROM MovieDatabase.Reviews R
    WHERE R.MovieID = @MovieID AND R.ReviewingUserID = @UserID
  )
  INSERT MovieDatabase.Reviews(ReviewingUserID, MovieID, [Text], StarRating)
  VALUES(@UserID, @MovieID, @Text, @StarRating)
ELSE
  UPDATE MovieDatabase.Reviews
  SET
    [Text] = @Text,
    StarRating = @StarRating
  WHERE MovieID = @MovieID AND ReviewingUserID = @UserID
GO

--Create new Watchlist
CREATE OR ALTER PROCEDURE MovieDatabase.CreateWatchlist
  @UserID INT, @MovieID INT
AS
INSERT MovieDatabase.Watchlists(UserID, MovieID)
VALUES(@UserID, @MovieID)
GO


--UPDATE AND SOFT DELETE STORED PROCEDURES

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

--Delete (Update IsDeleted) Movie
CREATE OR ALTER PROCEDURE MovieDatabase.DeleteMovie
  @MovieID INT, @IsAdmin INT
AS
IF @IsAdmin = 1
  UPDATE MovieDatabase.Movies
  SET
    IsDeleted = 1
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
