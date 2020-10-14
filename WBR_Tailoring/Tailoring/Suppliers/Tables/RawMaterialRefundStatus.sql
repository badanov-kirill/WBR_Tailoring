CREATE TABLE [Suppliers].[RawMaterialRefundStatus]
(
	rmrs_id         TINYINT NOT NULL CONSTRAINT [PK_RawMaterialRefundStatus] PRIMARY KEY CLUSTERED,
	rmrs_name       VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              DATETIME2(0) NOT NULL
)
GO