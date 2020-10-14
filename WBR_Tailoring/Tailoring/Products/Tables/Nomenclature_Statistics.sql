CREATE TABLE [Products].[Nomenclature_Statistics]
(
	nm_id                          INT CONSTRAINT [PK_Nomenclature_Statistics] PRIMARY KEY CLUSTERED NOT NULL,
	sale_qty                       INT NULL,
	sale_amount                    DECIMAL(15, 2) NULL,
	turnover                       INT NULL,
	effective_percent_discount     INT NULL,
	income_qty                     INT NULL,
	ordered_qty                    INT NULL
)

GO

GRANT DELETE
    ON OBJECT::[Products].[Nomenclature_Statistics] TO [WILDBERRIES\sqlreport]
    AS [dbo];
GO

GRANT INSERT
    ON OBJECT::[Products].[Nomenclature_Statistics] TO [WILDBERRIES\sqlreport]
    AS [dbo];
GO

GRANT UPDATE
    ON OBJECT::[Products].[Nomenclature_Statistics] TO [WILDBERRIES\sqlreport]
    AS [dbo];
GO

GRANT ALTER
    ON OBJECT::[Products].[Nomenclature_Statistics] TO [WILDBERRIES\sqlreport]
    AS [dbo];
GO

