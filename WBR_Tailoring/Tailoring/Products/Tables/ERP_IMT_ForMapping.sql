CREATE TABLE [Products].[ERP_IMT_ForMapping]
(
	imt_id            INT CONSTRAINT [PK_ERP_IMT_ForMapping] PRIMARY KEY CLUSTERED NOT NULL,
	descr             VARCHAR(1000) NOT NULL,
	sa                VARCHAR(36) NOT NULL,
	brand_id          INT NOT NULL,
	collection_id     INT NULL,
	season_id         INT NULL,
	kind_id           INT NULL,
	subject_id        INT NULL,
	style_id          INT NULL,
	dt                DATETIME2(0) NOT NULL
)
