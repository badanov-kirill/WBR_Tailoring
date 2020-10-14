CREATE TABLE [Products].[SketchOld]
(
	so_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_SketchOld] PRIMARY KEY CLUSTERED NOT NULL,
	brand_id              INT CONSTRAINT [FK_SketchOld_brand_id] FOREIGN KEY REFERENCES Products.Brand(brand_id) NULL,
	st_id                 INT CONSTRAINT [FK_SketchOld_st_id] FOREIGN KEY REFERENCES Products.SketchType(st_id) NULL,
	subject_id            INT CONSTRAINT [FK_SketchOld_subject_id] FOREIGN KEY REFERENCES Products.[Subject](subject_id) NULL,
	season_id             INT CONSTRAINT [FK_SketchOld_season_id] FOREIGN KEY REFERENCES Products.Season(season_id) NULL,
	model_year            SMALLINT NULL,
	sa_local              VARCHAR(15) NULL,
	sa                    VARCHAR(15) NULL,
	path_name             VARCHAR(150) NOT NULL,
	art_name              VARCHAR(150) NOT NULL,
	full_name             VARCHAR(200) NOT NULL,
	pattern_office_id     INT NULL,
	model_number          INT NULL,
	employee_id           INT NOT NULL,
	dt                    dbo.SECONDSTIME NOT NULL,
	is_deleted            BIT CONSTRAINT [DF_SketchOld_is_deleted] DEFAULT(0) NOT NULL,
	ct_id				  INT CONSTRAINT [FK_SketchOld_ct_id] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NULL
)