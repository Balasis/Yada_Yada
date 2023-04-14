--Version Microsoft SQL Server 2022 (RTM) - 16.0.1000.6 (X64)
--Brought to you by YadaYada production .
IF EXISTS(SELECT name FROM master.dbo.sysdatabases WHERE name = 'IMDb_YadaYada')
BEGIN
  ALTER DATABASE IMDb_YadaYada SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE IMDb_YadaYada;
END

CREATE DATABASE IMDb_YadaYada;
GO
USE IMDb_YadaYada;


CREATE TABLE Award (
    AwardID BIGINT NOT NULL IDENTITY(1,1),
    SeriesID BIGINT,
    MoviesID BIGINT,
    FilmCrewID BIGINT NOT NULL,
    AcademyAward BIT,
    GoldenGlobe BIT,
    AcademyAwardTitle INT,
    GoldenGlobeTitle INT,
    WinnerOrNom BIT,
    Date DATE,
    Location NVARCHAR(100),
    Comment NVARCHAR(MAX),
    OscarOrGolden NVARCHAR(20) NOT NULL CONSTRAINT OscarOrGolden CHECK(OscarOrGolden IN ('Oscar','Golden Globe')),
	CONSTRAINT cantHaveBothSeriesAndMovie CHECK ((SeriesID IS NULL AND MoviesID IS NOT NULL)or(SeriesID IS NOT NULL AND MoviesID IS NULL)   ),
	CONSTRAINT cantHaveBothAwards CHECK ((AcademyAward IS NULL AND GoldenGlobe IS NOT NULL)or(AcademyAward IS NOT NULL AND GoldenGlobe IS NULL)   ),
   CONSTRAINT AW_titleOnlyIf_AcadAwardhasvalue CHECK  ((AcademyAward IS NULL AND AcademyAwardTitle IS  NULL) OR (GoldenGlobe IS  NULL AND GoldenGlobeTitle IS NULL)), 
   CONSTRAINT oscarOrGoldenGlobeAccordinglyToTypeOfAward CHECK ((AcademyAward IS NOT NULL  AND OscarOrGolden='Oscar')OR (GoldenGlobe IS NOT NULL AND OscarOrGolden='Golden Globe'))


);
GO


CREATE TABLE AcademyAwTitles (
  AcademyAwardID INT PRIMARY KEY,
  AcademyAwardTitle NVARCHAR(50)
  CONSTRAINT DOonotBeginwithSpace check (AcademyAwardTitle NOT LIKE ' %'),
  CONSTRAINT DOonotADDSpacesInTheENd check(AcademyAwardTitle NOT LIKE '% ')
);
GO



CREATE TABLE Critic (
  CriticID BIGINT PRIMARY KEY,
  URL NVARCHAR(100) CONSTRAINT CriticURLMustBeSecure CHECK (URL LIKE 'https://%[a-zA-Z0-9_/]%'),
  SeriesID BIGINT,
  MoviesID BIGINT,

);
GO



CREATE FUNCTION dbo.age
(
    @BornDate DATE,
    @DeathDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT, @BornDateLocal DATE, @DeathDateLocal DATE
    SET @BornDateLocal = @BornDate
    SET @DeathDateLocal = @DeathDate
    IF @DeathDateLocal IS NOT NULL
        SET @Age = DATEDIFF(YEAR, @BornDateLocal, @DeathDateLocal)
    ELSE
        SET @Age = DATEDIFF(YEAR, @BornDateLocal, GETDATE())
    RETURN @Age
END

GO


CREATE TABLE FilmCrew (
    FilmCrewID BIGINT PRIMARY KEY IDENTITY (1,1),
    FirstName NVARCHAR(20) NOT NULL,
    LastName NVARCHAR(20) NOT NULL,
    BornLocation NVARCHAR(100) ,
    DeathLocation NVARCHAR(100),
    BornDate DATE NOT NULL,
    DeathDate DATE ,
    Description NVARCHAR(MAX),
    FullName AS CONCAT(FirstName, ' ', LastName) PERSISTED,
    Top1Job NVARCHAR(50) NULL,
    Top2Job NVARCHAR(50) NULL,
    Top3Job NVARCHAR(50) NULL,
    Age AS dbo.Age(BornDate,DeathDate),
    VidNum INT NULL,
    PicNum INT NULL,
	CONSTRAINT FullnamEe_MustBe_FirstAndLastName CHECK (Fullname=CONCAT(FirstName, ' ', LastName)),
	CONSTRAINT DeathDateCantBesmallerThanBornDate CHECK ((DeathDate IS NOT NULL AND BornDate<DeathDate)OR (DeathDate IS NULL ))
);
GO


CREATE TABLE Genre (
  GenreID INT PRIMARY KEY IDENTITY(1,1),
  GenreTitle NVARCHAR(50) ,
  CONSTRAINT genreNospace CHECK (GenreTitle NOT LIKE '[^ ]'),
  CONSTRAINT DOnotBeginwithSpace check (GenreTitle NOT LIKE ' %'),
  CONSTRAINT DOnotADDSpacesInTheENd check(GenreTitle NOT LIKE '% ')
);
GO

CREATE TABLE GoldenGlobeTitles (
  GoldenGlobeID INT PRIMARY KEY,
  GoldenGlobeTitle NVARCHAR(50)
    CONSTRAINT DOonottBeginwithSpace check (GoldenGlobeTitle NOT LIKE ' %'),
  CONSTRAINT DOonottADDSpacesInTheENd check(GoldenGlobeTitle NOT LIKE '% ')
);
GO


CREATE TABLE Image(
ImageID BIGINT Primary key IDENTITY(1,1),
SeriesID BIGINT,
MovieID BIGINT,
URL NVARCHAR(100) CONSTRAINT URLrelativeStruc CHECK (URL LIKE '%/[a-zA-Z0-9_/]%'),
Info NVARCHAR(100),
CONSTRAINT ChooseSeriesIDOrMovieIDnotBothh CHECK ( (SeriesID is null and MovieID IS NOT NULL) OR (SeriesID IS NOT NULL and MovieID is NULL) )

)

GO


CREATE TABLE Job (
    JobID INT PRIMARY KEY IDENTITY(1,1),
    MemberOfCrewID BIGINT NOT NULL,
    JobsTitlesID NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    StarOrNot BIT,
    Role NVARCHAR(100),
 
);


GO


CREATE TABLE JobsTitle (
    JobsID INT PRIMARY KEY IDENTITY(1,1),
    JobsTitle NVARCHAR(100),
	CONSTRAINT DONnotBeginwithSpace check (JobsTitle NOT LIKE ' %'),
  CONSTRAINT DONnotADDSpacesInTheENd check(JobsTitle NOT LIKE '% ')
);
GO

CREATE TABLE MemberOfCrew (
    MemberOfCrewID BIGINT PRIMARY KEY IDENTITY(1,1),
    FilmCrewID BIGINT NOT NULL,
    SeriesID BIGINT,
    MoviesID BIGINT,
    MoviesOrSeries NVARCHAR(30) NOT NULL,
  CONSTRAINT eITHERmovORseries  CHECK((MoviesID IS NULL AND SeriesID IS NOT NULL) OR (SeriesID IS NULL AND MoviesID IS NOT NULL)),
  CONSTRAINT UniGroup UNIQUE (FilmCrewID,SeriesID,MoviesID),
   CONSTRAINT MovieOrSeries CHECK((lower(MoviesOrSeries)='movie' AND MoviesID IS NOT NULL)OR(lower(MoviesOrSeries)='series') AND SeriesID IS NOT NULL )
);
GO


CREATE TABLE Movie (
  MoviesID BIGINT PRIMARY KEY IDENTITY (1,1),
  Genre1 INT NOT NULL,
  Genre2 INT,
  Genre3 INT,
  Duration TIME,
  Description NVARCHAR(MAX) CONSTRAINT MoviesDescriptionCantBeEmpty CHECK(LEN(LTRIM(RTRIM(Description))) <>0),
  ReleaseYear INT NOT NULL,
  ReleaseDate DATE NOT NULL,
  TrailerURL NVARCHAR(100) CONSTRAINT MoviesTrailerURLstructure CHECK (TrailerURL LIKE '%/[a-zA-Z0-9_/]%'),
  Title NVARCHAR(100) NOT NULL CONSTRAINT MoviesTitleCantBeOnlySpaces CHECK(LEN(LTRIM(RTRIM(Title))) <>0),
  CoverURL NVARCHAR(100)  CONSTRAINT MoviesCoverURLstructure CHECK (CoverURL LIKE '%/[a-zA-Z0-9_/]%'),
  Location NVARCHAR(100),
  VideosNum INT default 0,
  ImagesNum INT default 0,
  ReviewsNum BIGINT default 0,
  PopularityDiff INT default 0,
  PageViewsNum BIGINT default 0,
  TopRatedTV INT,
  StarRating NUMERIC(2,1),
  AwardWinsNum INT default 0,
  AwardNominNum INT default 0,
  Popularity INT,
  CONSTRAINT checkReleaseDateWithYear CHECK (DATEDIFF(YEAR,CAST(cast(ReleaseYear AS varchar(4))+'-01-01' AS DATE) ,ReleaseDate)=0)
);
GO


CREATE TABLE PicOrVidURL (
    PicOrVidURLID BIGINT PRIMARY KEY IDENTITY(1,1),
    FilmCrewID BIGINT NOT NULL,
    URL NVARCHAR(100) NOT NULL CONSTRAINT pICOrVidURLstructure CHECK (URL LIKE '%/[a-zA-Z0-9_/]%'),
    IsItPicOrVid BIT NOT NULL,
    Comment NVARCHAR(MAX),
   
);
GO


CREATE TABLE Review (
  ReviewID BIGINT PRIMARY KEY IDENTITY(1,1),
  UsersID BIGINT NOT NULL,
  SeriesID BIGINT,
  MoviesID BIGINT,
  Spoiler BIT,
  Date DATE NOT NULL,
  Header NVARCHAR(100) CONSTRAINT lengthCantBeZero CHECK(LEN(LTRIM(RTRIM(Header)))<>0),
  Body NVARCHAR(200) NOT NULL,
  VotesNum BIGINT NULL,
  VotesPlus BIGINT NULL,
  CONSTRAINT EitherSeriesORMovie CHECK ((SeriesID IS NOT NULL AND MoviesID IS NULL) OR (SeriesID IS NULL and MoviesID IS NOT NULL))
);
GO


CREATE TABLE Series (
  SeriesID BIGINT PRIMARY KEY IDENTITY(1,1),
  Genre1 INT NOT NULL,
  Genre2 INT,
  Genre3 INT,
  Media NVARCHAR(100),
  Duration TIME,
  Timespan TIME,
  Description NVARCHAR(MAX) CONSTRAINT SeriesDescriptionCantBeEmpty CHECK(LEN(LTRIM(RTRIM(Description))) <>0),
  Seasons INT CONSTRAINT SeriesSeasonsAtLeastOne CHECK(Seasons >=1),
  EpisodesNum INT CONSTRAINT EpisodesNumAtLeastOne CHECK(EpisodesNum >=1),
  Years INT ,
  TrailerURL NVARCHAR(100) CONSTRAINT SeriesTrailerURLstructure CHECK (TrailerURL LIKE '%/[a-zA-Z0-9_/]%'),
  Title NVARCHAR(100) NOT NULL CONSTRAINT SeriesTitleCantBeOnlySpaces CHECK(LEN(LTRIM(RTRIM(Title))) <>0),
  CoverURL NVARCHAR(100) CONSTRAINT SeriesCoverURLstructure CHECK (CoverURL LIKE '%/[a-zA-Z0-9_/]%'),
  VideosNum BIGINT NULL default 0,
  ImagesNum BIGINT NULL default 0,
  ReviewsNum BIGINT NULL default 0,
    PopularityDiff INT NULL default 0,
  TopRatedTV INT NULL,
   StarRating NUMERIC(2,1) NULL,
   Popularity INT NULL,
   AwardWinsNum INT NULL default 0,
   PageViewsNum INT NULL default 0,
  AwardNominNum INT NULL default 0,
  )
GO


CREATE TABLE [User] (
  UsersID BIGINT PRIMARY KEY IDENTITY(1,1),
  FirstName NVARCHAR(20) NOT NULL CONSTRAINT FirstName_MustBe_2To20Char_FirstTwoMustBeNotBeNumeric CHECK (LEN(FirstName) >=2 AND FirstName Like '[A-Za-z][A-Za-z]%' AND FirstNAME NOT LIKE '% %'),
  LastName NVARCHAR(20) NOT NULL CONSTRAINT LastName_MustBe_2To20Char_FirstTwoMustBeNotBeNumeric CHECK (LEN(LastName) >=2 AND LastName Like '[A-Za-z][A-Za-z]%' AND LastName NOT LIKE '% %'),
  Session_ID NVARCHAR(100),
  Password NVARCHAR(20) NOT NULL CONSTRAINT Password_MustBe_8To20Chars CHECK (LEN(Password) >=8 AND Password NOT LIKE '%[^a-zA-Z0-9]%'),
  Email NVARCHAR(100) NOT NULL CHECK (lower(Email) LIKE '%@gmail.com' OR lower(Email) LIKE '%@outlook.com' OR lower(Email) LIKE '%@yahoo.com'),
  FullName AS CONCAT(FirstName, ' ', LastName) PERSISTED,
  CONSTRAINT Fullname_MustBe_FirstAndLastName CHECK (Fullname=CONCAT(FirstName, ' ', LastName)),
  CONSTRAINT emailNoSpace CHECK (Email NOT LIKE '% %'),
  CONSTRAINT emailStructure CHECK (Email LIKE '%_@__%.__%')
  

);
GO


CREATE TABLE UsersVote (
  UsersID BIGINT NOT NULL,
  ReviewID BIGINT NOT NULL,
  Vote INT CHECK(VOTE IN (0,1)) NOT NULL,
  CONSTRAINT PK_UsersVote PRIMARY KEY (UsersID, ReviewID)
);
GO



CREATE TABLE Video(
VideoID BIGINT Primary key IDENTITY(1,1),
SeriesID BIGINT,
MovieID BIGINT,
URL NVARCHAR(100) CONSTRAINT URLMustBeSecure CHECK (URL LIKE '%/[a-zA-Z0-9_/]%'),
Info NVARCHAR(100),
CONSTRAINT ChooseSeriesIDOrMovieIDnotBoth CHECK ( (SeriesID is null and MovieID IS NOT NULL) OR (SeriesID IS NOT NULL and MovieID is NULL) )

)

GO


CREATE TABLE VoteForM (
  MoviesID BIGINT NOT NULL,
  UsersID BIGINT NOT NULL,
  Vote NUMERIC(2,0) NOT NULL CONSTRAINT voteforMvote CHECK(VOTE BETWEEN 1 AND 10),
  VoteDate DATETIME NULL DEFAULT GETDATE(),
  PRIMARY KEY (MoviesID, UsersID),
 
);
GO


CREATE TABLE VoteForS (
  SeriesID BIGINT NOT NULL,
  UsersID BIGINT NOT NULL,
  Vote NUMERIC(2,0) NOT NULL CHECK (Vote BETWEEN 1 AND 10),
  VoteDate DATETIME NULL DEFAULT GETDATE(),
  PRIMARY KEY(SeriesID,UsersID)
);
GO



CREATE Procedure dbo.ScheduledVotes
AS
BEGIN
DECLARE @LastUpdated DATE
SET @LastUpdated=(SELECT MAX(LastUpdate) FROM LastUpdateVotes)


 UPDATE Series
SET StarRating = ( 	
    (SELECT SUM(Vote) FROM VoteForS WHERE VoteForS.SeriesID = Series.SeriesID AND VoteForS.VoteDate>@LastUpdated)/(SELECT COUNT(*) FROM VoteForS WHERE VoteForS.VoteDate>@LastUpdated AND VoteForS.SeriesID=Series.SeriesID)  )
	 
UPDATE Movie
SET StarRating = ( 	
    (SELECT SUM(Vote) FROM VoteForM WHERE VoteForM.MoviesID = Movie.MoviesID AND VoteForM.VoteDate>@LastUpdated)/(SELECT COUNT(*) FROM VoteForM WHERE VoteForM.VoteDate>@LastUpdated AND VoteForM.MoviesID=Movie.MoviesID)  )
	 INSERT INTO LastUpdateVotes(LastUpdate) VALUES (GETDATE());
END

GO
DECLARE @job_name NVARCHAR(128);
SET @job_name = N'ScheduledVotes_'+CAST(NEWID() AS NVARCHAR(36));

DECLARE @job_id UNIQUEIDENTIFIER;
EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @job_id = @job_id OUTPUT;

	
DECLARE @job_description NVARCHAR(MAX);
SET @job_description = N'FillTheStarRates_' +CAST(NEWID() AS NVARCHAR(36));

DECLARE @command NVARCHAR(MAX);
SET @command = N'EXEC ' + DB_NAME() + '.dbo.ScheduledVotes';
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = @job_name,
    @step_name = N'Otinane',
    @subsystem = N'TSQL',
    @command = @command,
    @retry_attempts = 5,--sometimes procedure fail so here you tell it how many times to retry
    @retry_interval = 1;-- and here how much time to wait after each try

DECLARE @schedule_name NVARCHAR(128);
SET @schedule_name = N'DenToVlepwNaKimame_'+CAST(NEWID() AS NVARCHAR(36));

EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = @schedule_name,
    @freq_type = 4,--4means daily.Ifyou want weekly go for 8 or monthly for 8 (but not suggested this is rating MovAndSer) 
    @freq_interval = 1,--every when..if freq type is 4 means 1 means every day,if it was 8 means every week e.t.c
    @active_start_time = 050000;--the time here is like HH/MM/SS

EXEC msdb.dbo.sp_attach_schedule
    @job_name = @job_name,
    @schedule_name = @schedule_name;

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @job_name;

GO

-- update the awardNomNum and awardWin of Movies and series
CREATE TRIGGER AwardWinAndNom
on Award AFTER INSERT,UPDATE,DELETE
AS
BEGIN

IF EXISTS(SELECT * FROM INSERTED) 
BEGIN
		IF (SELECT MoviesID FROM INSERTED )IS NOT NULL
	BEGIN
	UPDATE Movie SET AwardNominNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=0 AND MoviesID=(SELECT MoviesID from INSERTED) ) WHERE MoviesID=(SELECT MoviesID from INSERTED)
	UPDATE Movie SET AwardWinsNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=1 AND MoviesID=(SELECT MoviesID from INSERTED) ) WHERE MoviesID=(SELECT MoviesID from INSERTED)
	END
	IF (SELECT SeriesID FROM INSERTED ) IS NOT NULL
	BEGIN
	UPDATE Series SET AwardNominNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=0 AND SeriesID=(SELECT SeriesID from INSERTED) ) WHERE SeriesID=(SELECT MoviesID from INSERTED)
	UPDATE Series SET AwardWinsNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=1 AND SeriesID=(SELECT SeriesID from INSERTED) ) WHERE SeriesID=(SELECT MoviesID from INSERTED)
	END

END

IF EXISTS (SELECT * FROM DELETED)
BEGIN
					IF (SELECT MoviesID FROM DELETED )IS NOT NULL
	BEGIN
	UPDATE Movie SET AwardNominNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=0 AND MoviesID=(SELECT MoviesID from DELETED) ) WHERE MoviesID=(SELECT MoviesID from DELETED)
	UPDATE Movie SET AwardWinsNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=1 AND MoviesID=(SELECT MoviesID from DELETED) ) WHERE MoviesID=(SELECT MoviesID from DELETED)
	END
	IF (SELECT SeriesID FROM DELETED ) IS NOT NULL
	BEGIN
	UPDATE Series SET AwardNominNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=0 AND SeriesID=(SELECT SeriesID from DELETED) ) WHERE SeriesID=(SELECT MoviesID from DELETED)
	UPDATE Series SET AwardWinsNum=(SELECT COUNT(*) FROM Award WHERE WinnerOrNom=1 AND SeriesID=(SELECT SeriesID from DELETED) ) WHERE SeriesID=(SELECT MoviesID from DELETED)
	END
END

END

GO

--Like the videos this one update the number of images in Movie or series
CREATE TRIGGER [dbo].[ImageNum]
ON [Image] AFTER INSERT,UPDATE,DELETE
AS
BEGIN
IF EXISTS(SELECT * FROM INSERTED) 
BEGIN
	
	IF (SELECT MovieID FROM INSERTED )IS NOT NULL
	BEGIN
	UPDATE Movie SET ImagesNum=(SELECT COUNT(*) FROM Image WHERE MovieID=(SELECT MovieID FROM inserted )) WHERE MoviesID=(SELECT MovieID FROM INSERTED)
	 END
		ELSE
 
	 IF (SELECT SeriesID FROM INSERTED ) IS NOT NULL
	BEGIN
	 UPDATE Series SET ImagesNum=(SELECT COUNT(*) FROM Image WHERE SeriesID=(SELECT SeriesID FROM INSERTED ))WHERE SeriesID=(SELECT SeriesID FROM INSERTED)
	END
END

IF EXISTS(SELECT * FROM DELETED)
BEGIN
 	IF (SELECT MovieID FROM DELETED)IS NOT NULL
	BEGIN
	UPDATE Movie SET ImagesNum=(SELECT COUNT(*) FROM Image WHERE MovieID=( SELECT MovieID FROM DELETED ) ) WHERE MoviesID=( SELECT MovieID FROM DELETED)
	END
	ELSE
 
	IF (SELECT SeriesID FROM DELETED) IS NOT NULL
	 BEGIN
	UPDATE Series SET ImagesNum=(SELECT COUNT(*) FROM Image WHERE SeriesID=( SELECT SeriesID FROM DELETED)) WHERE SeriesID=(SELECT SeriesID FROM DELETED)
	END

END



END
GO


--update the number of videos or photos of the filmCrew
CREATE TRIGGER PicOrVidOfFilmCrew
ON PicOrVidURL AFTER INSERT,UPDATE,DELETE
AS
BEGIN

IF EXISTS(SELECT * FROM INSERTED) 
BEGIN

 UPDATE FilmCrew SET 
 PicNum=( SELECT COUNT(*) FROM PicOrVidURL WHERE FilmCrewID=(SELECT FilmCrewID FROM INSERTED) AND IsItPicOrVid=0) ,
  VidNum=( SELECT COUNT(*) FROM PicOrVidURL WHERE FilmCrewID=(SELECT FilmCrewID FROM INSERTED) AND IsItPicOrVid=1)
  WHERE FilmCrewID IN (SELECT FilmCrewID FROM INSERTED) 


END


IF EXISTS(SELECT * FROM DELETED)
BEGIN
 UPDATE FilmCrew SET 
 PicNum=( SELECT COUNT(*) FROM PicOrVidURL WHERE FilmCrewID=(SELECT FilmCrewID FROM DELETED) AND IsItPicOrVid=0) ,
  VidNum=( SELECT COUNT(*) FROM PicOrVidURL WHERE FilmCrewID=(SELECT FilmCrewID FROM DELETED) AND IsItPicOrVid=1)
  WHERE FilmCrewID IN (SELECT FilmCrewID FROM DELETED) 


END



 END



GO



-- The following Updates the votes in each review
create TRIGGER [dbo].[UpdateVotes]
On UsersVote
AFTER INSERT,UPDATE,DELETE
AS
BEGIN

IF EXISTS(SELECT * FROM INSERTED) 
BEGIN


UPDATE Review
SET VotesNum=(SELECT COUNT(*) FROM UsersVote WHERE ReviewID=COALESCE((SELECT ReviewID FROM inserted), (SELECT ReviewID FROM DELETED))   ),
	VotesPlus=(SELECT COUNT(*) FROM UsersVote WHERE ReviewID=COALESCE((SELECT ReviewID FROM inserted), (SELECT ReviewID FROM DELETED))  AND Vote=1)
	WHERE ReviewID=COALESCE((SELECT ReviewID FROM inserted),(SELECT ReviewID FROM DELETED) )
END

IF EXISTS(SELECT * FROM DELETED)
BEGIN

UPDATE Review
SET VotesNum=(SELECT COUNT(*) FROM UsersVote WHERE ReviewID=(SELECT ReviewID FROM DELETED))   ,
	VotesPlus=(SELECT COUNT(*) FROM UsersVote WHERE ReviewID=(SELECT ReviewID FROM DELETED)  AND Vote=1)
	WHERE ReviewID=(SELECT ReviewID FROM DELETED) 

END



END
GO


--This updates the videoNum of series and movies.no worries it doesn't trigger as a whole as you see.
CREATE TRIGGER [dbo].[VideoNum]
ON Video AFTER INSERT,UPDATE,DELETE
AS
BEGIN
IF EXISTS(SELECT * FROM INSERTED) 
BEGIN
	
	IF (SELECT MovieID FROM INSERTED )IS NOT NULL
	BEGIN
	UPDATE Movie SET VideosNum=(SELECT COUNT(*) FROM Video WHERE MovieID=(SELECT MovieID FROM inserted )) WHERE MoviesID=(SELECT MovieID FROM INSERTED)
	 END
		ELSE
 
	 IF (SELECT SeriesID FROM INSERTED ) IS NOT NULL
	BEGIN
	 UPDATE Series SET VideosNum=(SELECT COUNT(*) FROM Video WHERE SeriesID=(SELECT SeriesID FROM INSERTED ))WHERE SeriesID=(SELECT SeriesID FROM INSERTED)
	END
END

IF EXISTS(SELECT * FROM DELETED)
BEGIN
 	IF (SELECT MovieID FROM DELETED)IS NOT NULL
	BEGIN
	UPDATE Movie SET VideosNum=(SELECT COUNT(*) FROM Video WHERE MovieID=( SELECT MovieID FROM DELETED ) ) WHERE MoviesID=( SELECT MovieID FROM DELETED)
	END
	ELSE
 
	IF (SELECT SeriesID FROM DELETED) IS NOT NULL
	 BEGIN
	UPDATE Series SET VideosNum=(SELECT COUNT(*) FROM Video WHERE SeriesID=( SELECT SeriesID FROM DELETED)) WHERE SeriesID=(SELECT SeriesID FROM DELETED)
	END

END



END
GO

--Update the date of the row that is modified.As for insert theres no need since theres default getdate
CREATE TRIGGER UpdDate
ON VoteForM AFTER UPDATE
AS
BEGIN
UPDATE VoteForM SET VoteDate=GETDATE() WHERE MoviesID=(SELECT MoviesID FROM INSERTED) AND UsersID=(SELECT UsersID FROM INSERTED);
END
GO


-- Updates the date in the VoteForS (ovies) because we need to compare it with the lastUpdate one.On insert there is default update date so no need)
CREATE TRIGGER UpddDate
ON VoteForS AFTER UPDATE
AS
BEGIN
UPDATE VoteForS SET VoteDate=GETDATE() WHERE SeriesID=(SELECT SeriesID FROM INSERTED) AND UsersID=(SELECT UsersID FROM INSERTED);
END
GO


ALTER TABLE VoteForS
ADD CONSTRAINT FK_VoteForSSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID),
	CONSTRAINT FK_VoteForSUserID	FOREIGN KEY(UsersID) REFERENCES [User](UsersID)

ALTER TABLE VoteForM
ADD CONSTRAINT FK_VoteForMMoviesID	FOREIGN KEY(MoviesID)	REFERENCES  Movie(MoviesID),
	CONSTRAINT FK_VoteForMUserID	FOREIGN KEY(UsersID) REFERENCES [User](UsersID)

ALTER TABLE UsersVote
ADD CONSTRAINT FK_UsersVoteReviewID	FOREIGN KEY(ReviewID)	REFERENCES Review(ReviewID),
	CONSTRAINT FK_UsersVoteUserID	FOREIGN KEY(UsersID) REFERENCES [User](UsersID)

ALTER TABLE Review
ADD CONSTRAINT FK_ReviewMoviesID FOREIGN KEY(MoviesID)	REFERENCES  Movie(MoviesID),
	CONSTRAINT FK_ReviewUserID	FOREIGN KEY(UsersID) REFERENCES [User](UsersID),
	CONSTRAINT FK_ReviewSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID)

ALTER TABLE Series
ADD CONSTRAINT FK_SeriesGenre1	FOREIGN KEY(Genre1)	REFERENCES  Genre(GenreID),
	CONSTRAINT FK_SeriesGenre2	FOREIGN KEY(Genre2)	REFERENCES  Genre(GenreID),
	CONSTRAINT FK_SeriesGenre3	FOREIGN KEY(Genre3)	REFERENCES  Genre(GenreID)

ALTER TABLE Movie
ADD CONSTRAINT FK_MovieGenre1	FOREIGN KEY(Genre1)	REFERENCES  Genre(GenreID),
	CONSTRAINT FK_MovieGenre2	FOREIGN KEY(Genre2)	REFERENCES  Genre(GenreID),
	CONSTRAINT FK_MovieGenre3	FOREIGN KEY(Genre3)	REFERENCES  Genre(GenreID)

ALTER TABLE Award
ADD CONSTRAINT FK_AwardSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID),
	CONSTRAINT FK_AwardMoviesID FOREIGN KEY(MoviesID)	REFERENCES  Movie(MoviesID),
	CONSTRAINT FK_AwardFilmCrewID FOREIGN KEY(FilmCrewID) REFERENCES FilmCrew(FilmCrewID),
	CONSTRAINT FK_AwardAcademyAwardTitles FOREIGN KEY(AcademyAwardTitle) REFERENCES AcademyAwTitles(AcademyAwardID),
	CONSTRAINT FK_AwardGoldenGlobeTitles FOREIGN KEY(GoldenGlobeTitle) REFERENCES GoldenGlobeTitles(GoldenGlobeID)

ALTER TABLE PicOrVidURL
ADD CONSTRAINT FK_PicOrVidURLFilmCrewID FOREIGN KEY(FilmCrewID) REFERENCES FilmCrew(FilmCrewID)

ALTER TABLE MemberOfCrew
ADD CONSTRAINT FK_MemberOfCrewFilmCrewID FOREIGN KEY(FilmCrewID) REFERENCES FilmCrew(FilmCrewID),
	CONSTRAINT FK_MemberOfCrewSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID),
	CONSTRAINT FK_MemberOfCrewMoviesID FOREIGN KEY(MoviesID)	REFERENCES  Movie(MoviesID)

ALTER TABLE Job
ADD CONSTRAINT FK_JobMemberOfCrewID	FOREIGN KEY(MemberOfCrewID)	REFERENCES  MemberOfCrew(MemberOfCrewID),
	CONSTRAINT FK_JobJobsTitlesID	FOREIGN KEY(JobID) REFERENCES JobsTitle(JobsID)


ALTER TABLE Video
ADD CONSTRAINT FK_VideoSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID),
	CONSTRAINT FK_VideoMoviesID	FOREIGN KEY(MovieID)	REFERENCES  Movie(MoviesID)

ALTER TABLE Image
ADD CONSTRAINT FK_ImageSeriesID	FOREIGN KEY(SeriesID)	REFERENCES  Series(SeriesID),
	CONSTRAINT FK_ImageMoviesID	FOREIGN KEY(MovieID)	REFERENCES  Movie(MoviesID)
GO