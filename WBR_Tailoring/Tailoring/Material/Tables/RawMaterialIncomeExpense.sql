CREATE TABLE [Material].[RawMaterialIncomeExpense]
(
	rmie_id                INT IDENTITY(1, 1) NOT NULL CONSTRAINT [PK_RawMaterialIncomeExpense_rmie_id] PRIMARY KEY CLUSTERED,
	doc_id                 INT NOT NULL,
	doc_type_id            TINYINT NOT NULL CONSTRAINT [CH_RawMaterialIncomeExpense_doc_type_id] CHECK(doc_type_id = 1),
	amount                 DECIMAL(9, 2) NOT NULL,
	employee_id            INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	descript               VARCHAR(300) NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,	
	is_deleted             BIT NOT NULL CONSTRAINT [DF_RawMaterialIncomeExpense_is_deleted] DEFAULT(0)
)
GO