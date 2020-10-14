CREATE TABLE [Suppliers].[RawMaterialRefundSuspectDetail]
(
	rmrsd_id        INT NOT NULL IDENTITY(1, 1) CONSTRAINT [PK_RawMaterialRefundSuspectDetail] PRIMARY KEY CLUSTERED,
	rmr_id          INT NOT NULL CONSTRAINT [FK_RawMaterialRefundSuspectDetail_rmr_id] FOREIGN KEY REFERENCES Suppliers.RawMaterialRefund(rmr_id),
	shks_id         INT NOT NULL CONSTRAINT [FK_RawMaterialRefundSuspectDetail_shks_id] FOREIGN KEY REFERENCES Warehouse.SHKSuspectUnit(shks_id),
	qty             DECIMAL(9, 3) NOT NULL,
	okei_id         INT NOT NULL CONSTRAINT [FK_RawMaterialRefundSuspectDetail_okei_id] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id),
	is_deleted      BIT NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)	
GO