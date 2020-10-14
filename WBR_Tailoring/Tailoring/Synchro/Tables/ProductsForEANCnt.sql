CREATE TABLE [Synchro].[ProductsForEANCnt]
(
	pants_id        INT CONSTRAINT [FK_ProductsForEANCnt_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id) NOT NULL,
	cnt_create      INT NOT NULL,
	cnt_publish     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	dt_create       DATETIME2(0) NOT NULL,
	dt_publish      DATETIME2(0) NOT NULL,
	error_num       VARCHAR(10) NULL,
	error_name      VARCHAR(250) NULL,
	error_desc      VARCHAR(900) NULL,
	error_xml       VARCHAR(MAX) NULL,
	error_dt        DATETIME2(0) NULL
	CONSTRAINT [PK_ProductsForEANCnt] PRIMARY KEY CLUSTERED(pants_id)
)