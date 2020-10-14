CREATE TABLE [History].[RawMaterialRefund]
(
	log_id                  INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_History_RawMaterialRefund] PRIMARY KEY CLUSTERED,
	rmr_id                  INT NOT NULL,
	supplier_id             INT NOT NULL,
	suppliercontract_id     INT NOT NULL,
	rmrs_id                 TINYINT NOT NULL,
	sending_dt              DATE NULL,
	is_deleted              BIT NOT NULL,
	dt                      DATETIME2(0) NOT NULL,
	employee_id             INT NOT NULL,
	comment                 VARCHAR(200) NULL
)
GO