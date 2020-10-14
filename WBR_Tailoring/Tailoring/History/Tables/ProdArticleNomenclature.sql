CREATE TABLE [History].[ProdArticleNomenclature]
(
	hpan_id                       INT IDENTITY(1, 1) CONSTRAINT [PK_ProdArticleNomenclature] PRIMARY KEY CLUSTERED NOT NULL,
	pan_id                        INT NOT NULL,
	pa_id                         INT NOT NULL,
	sa                            VARCHAR(36) NOT NULL,
	is_deleted                    BIT NOT NULL,
	employee_id                   INT NOT NULL,
	dt                            dbo.SECONDSTIME NOT NULL,
	nm_id                         INT NULL,
	whprice                       DECIMAL(9, 2) NULL,
	price_ru                      DECIMAL(9, 2) NULL,
	cutting_degree_difficulty     DECIMAL(4, 2) NULL,
)
