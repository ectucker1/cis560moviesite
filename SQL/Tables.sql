
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