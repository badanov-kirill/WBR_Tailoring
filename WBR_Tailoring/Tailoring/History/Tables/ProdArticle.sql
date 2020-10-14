CREATE TABLE [History].[ProdArticle]
(
	hpa_id            INT IDENTITY(1, 1) CONSTRAINT [PK_History_ProdArticle] PRIMARY KEY CLUSTERED NOT NULL,
	pa_id             INT NOT NULL,
	sketch_id         INT NOT NULL,
	is_deleted        BIT NOT NULL,
	model_number      INT NOT NULL,
	brand_id          INT NOT NULL,
	season_id         INT NULL,
	collection_id     INT NULL,
	style_id          INT NULL,
	direction_id      INT NULL,
	employee_id       INT NOT NULL,
	dt                dbo.SECONDSTIME NOT NULL,
	ao_ts_id          INT NULL,
	is_not_new		  BIT NULL
)