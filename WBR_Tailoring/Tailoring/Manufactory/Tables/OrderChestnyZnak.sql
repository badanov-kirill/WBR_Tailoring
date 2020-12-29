CREATE TABLE [Manufactory].[OrderChestnyZnak]
(
	ocz_id          INT IDENTITY(1, 1) CONSTRAINT [PK_OrderChestnyZnak] PRIMARY KEY CLUSTERED NOT NULL,
	covering_id     INT CONSTRAINT [FK_OrderChestnyZnak_covering_id] FOREIGN KEY REFERENCES Planing.Covering(covering_id) NULL,
	create_dt       DATETIME2(0) NOT NULL,
	send_dt         DATETIME2(0) NULL,
	close_dt        DATETIME2(0) NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL,
	is_deleted      BIT NOT NULL,
	sign_dt			DATETIME2(0) NULL,
	ocz_uid			BINARY(16) NULL
)
