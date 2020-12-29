CREATE TABLE [Synchro].[OrderChestnyZnakCntLoadItem]
(
	oczd_id            INT CONSTRAINT [FK_OrderChestnyZnakCntLoadItem_oczd_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnakDetail(oczd_id),
	cnt_load           INT NOT NULL,
	dt                 DATETIME2(0) NOT NULL,
	timeout_second     INT NOT NULL,
	error_desc         VARCHAR(900) NULL,
	error_dt           DATETIME2(0) NULL,
	CONSTRAINT [PK_OrderChestnyZnakCntLoadItem] PRIMARY KEY CLUSTERED(oczd_id)
)
