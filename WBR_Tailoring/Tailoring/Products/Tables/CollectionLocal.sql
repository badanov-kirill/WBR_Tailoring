CREATE TABLE [Products].[CollectionLocal]
(
	season_model_year     SMALLINT NOT NULL,
	season_local_id       INT CONSTRAINT [FK_CollectionLocal_season_local_id] FOREIGN KEY REFERENCES Products.SeasonLocal(season_local_id) NOT NULL,
	brand_id              INT CONSTRAINT [FK_CollectionLocal_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	close_dt              DATETIME2(0) NULL,
	close_employee_id     INT NULL,
	CONSTRAINT [PK_CollectionLocal] PRIMARY KEY CLUSTERED (season_model_year, season_local_id, brand_id)  
)
