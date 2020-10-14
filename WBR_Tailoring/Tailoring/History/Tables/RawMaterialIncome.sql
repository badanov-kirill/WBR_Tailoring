CREATE TABLE [History].[RawMaterialIncome]
(
	log_id                 INT IDENTITY(1, 1) CONSTRAINT [PK_History_RawMaterialIncome] PRIMARY KEY CLUSTERED NOT NULL,
	doc_id                  INT NOT NULL,
	doc_type_id				TINYINT NOT NULL,
	rmis_id                 INT NOT NULL,
	dt                      dbo.SECONDSTIME NOT NULL,
	employee_id             INT NOT NULL,
	supplier_id             INT NOT NULL,
	suppliercontract_id     INT NOT NULL,
	supply_dt               dbo.SECONDSTIME NOT NULL,
	is_deleted              BIT NOT NULL,
	goods_dt                dbo.SECONDSTIME NULL,
	comment                 VARCHAR(200) NULL,
	payment_comment         VARCHAR(200) NULL,
	plan_sum                DECIMAL(18, 2) NULL,
	scan_load_dt            dbo.SECONDSTIME NULL
)
