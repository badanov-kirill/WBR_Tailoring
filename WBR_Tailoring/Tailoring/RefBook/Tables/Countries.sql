CREATE TABLE [RefBook].[Countries]
(
	country_id            INT NOT NULL,
	employee_id           INT NOT NULL,
	isdeleted             BIT NOT NULL,
	dt                    dbo.SECONDSTIME CONSTRAINT DF_Countries_dt DEFAULT(GETDATE()) NOT NULL,
	cod2b                 CHAR(2) NOT NULL,
	cod3b                 CHAR(3) NOT NULL,
	country_name          VARCHAR(100) NOT NULL,
	full_country_name     VARCHAR(100) NOT NULL,
	rv                    ROWVERSION NOT NULL,
	yandex_name           VARCHAR(64) NULL,
	CONSTRAINT PK_Countries PRIMARY KEY CLUSTERED(country_id ASC),
	CONSTRAINT CH_Country_Len CHECK(LEN(country_name) > (2))
)
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_cod2b ON RefBook.Countries(cod2b ASC) ON [Indexes];
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_cod3b ON RefBook.Countries(cod3b ASC) ON [Indexes];
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_Countries_name ON RefBook.Countries(country_name ASC) ON [Indexes];
GO
