CREATE TABLE [Logistics].[TransferBox]
(
	transfer_box_id        BIGINT CONSTRAINT [PK_TransferBox] PRIMARY KEY CLUSTERED NOT NULL,
	create_dt              DATETIME2(0) NOT NULL,
	create_employee_id     INT NOT NULL,
	close_dt               DATETIME2(0) NULL,
	close_employee_id      INT NULL,
	plan_shipping_dt	   DATE NULL
)
