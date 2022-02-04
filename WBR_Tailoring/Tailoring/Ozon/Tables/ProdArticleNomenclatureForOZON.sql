CREATE TABLE [Ozon].[ProdArticleNomenclatureForOZON]
(
	pan_id              INT CONSTRAINT [FK_ProdArticleNomenclatureForOnon_pan_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclature(pan_id) NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	send_dt             DATETIME2(0) NULL,
	is_error            BIT NULL,
	load_ozon_id_dt     DATETIME2(0) NULL,
	is_deleted          BIT NOT NULL,
	employee_id			INT NULL,
	CONSTRAINT [PK_ProdArticleNomenclatureForOzon] PRIMARY KEY CLUSTERED(pan_id)
)

