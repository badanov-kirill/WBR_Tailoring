CREATE TABLE [Planing].[CollectionLocalMatrix]
(
	season_model_year     SMALLINT NOT NULL,
	season_local_id       INT CONSTRAINT [FK_CollectionLocalMatrix_season_local_id] FOREIGN KEY REFERENCES Products.SeasonLocal(season_local_id) NOT NULL,
	brand_id              INT CONSTRAINT [FK_CollectionLocalMatrix_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NOT NULL,
	subject_id            INT CONSTRAINT [FK_CollectionLocalMatrix_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NOT NULL,
	plan_qty              SMALLINT NOT NULL,
	employee_id           INT NOT NULL,
	dt                    DATETIME2(0) NOT NULL
	CONSTRAINT [PK_CollectionLocalMatrix] PRIMARY KEY CLUSTERED(season_model_year, season_local_id, brand_id, subject_id)
)
