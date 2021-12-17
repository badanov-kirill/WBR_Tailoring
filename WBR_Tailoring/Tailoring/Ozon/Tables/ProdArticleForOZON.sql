﻿CREATE TABLE [Ozon].[ProdArticleForOZON]
(
	pa_id               INT CONSTRAINT [FK_ProdArticleForWB_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	send_dt             DATETIME2(0) NULL,
	is_error            BIT NULL,
	load_ozon_id_dt     DATETIME2(0) NULL,
	report_id           INT NULL,
	CONSTRAINT [PK_ProdArticleForWB] PRIMARY KEY CLUSTERED(pa_id)
)

