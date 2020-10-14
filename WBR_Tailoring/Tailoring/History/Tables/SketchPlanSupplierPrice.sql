CREATE TABLE [History].[SketchPlanSupplierPrice]
(
	hspsp_id        INT IDENTITY(1, 1) CONSTRAINT [PK_History_SketchPlanSupplierPrice] PRIMARY KEY CLUSTERED NOT NULL,
	spsp_id         INT NOT NULL,
	sp_id           INT NOT NULL,
	supplier_id     INT NOT NULL,
	price_ru        DECIMAL(9, 2) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	comment         VARCHAR(200) NULL,
	order_num       VARCHAR(10) NULL
)