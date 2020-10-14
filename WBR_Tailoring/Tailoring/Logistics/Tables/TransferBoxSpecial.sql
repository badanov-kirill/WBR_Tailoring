CREATE TABLE [Logistics].[TransferBoxSpecial]
(
	transfer_box_id          BIGINT CONSTRAINT [FK_TransferBoxSPECIAL_transfer_box_id] FOREIGN KEY REFERENCES Logistics.TransferBox(transfer_box_id) NOT NULL,
	plan_shipping_dt         DATETIME2(0) NOT NULL,
	office_id                INT CONSTRAINT [FK_TransferBoxSpecial_office_id] FOREIGN KEY REFERENCES Settings.OfficeSetting(office_id) NOT NULL,
	shipping_dt              DATETIME2(0) NULL,
	shipping_employee_id     INT NULL,
	print_dt                 DATETIME2(0) NULL,
	print_employee_id        INT NULL,
	CONSTRAINT [PK_TransferBoxSpecial] PRIMARY KEY CLUSTERED(transfer_box_id)
)