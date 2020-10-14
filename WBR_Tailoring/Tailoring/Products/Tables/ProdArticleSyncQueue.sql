CREATE TABLE [Products].[ProdArticleSyncQueue]
(
	pa_id           INT CONSTRAINT [FK_ProdArticleSyncQueue_pa_id] FOREIGN KEY REFERENCES Products.ProdArticle(pa_id) NOT NULL,
	rv              ROWVERSION NOT NULL,
	create_dt       DATETIME2(0) NOT NULL,
	send_dt         DATETIME2(0) NULL,
	request_dt      DATETIME2(0) NULL,
	spec_uid        VARCHAR(36) NULL,
	cnt_request     TINYINT CONSTRAINT [DF_ProdArticleSyncQueue_cnt_request] DEFAULT(0) NOT NULL,
	cnt_get_nm      TINYINT CONSTRAINT [DF_ProdArticleSyncQueue_cnt_get_nm] DEFAULT(0) NOT NULL,
	CONSTRAINT [PK_ProdArticleSyncQueue] PRIMARY KEY CLUSTERED(pa_id)
)
