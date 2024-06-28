CREATE TABLE [Synchro].[OrderChestnyZnakSign]
(
	ocz_id             INT CONSTRAINT [FK_OrderChestnyZnakSign_ocz_id] FOREIGN KEY REFERENCES Manufactory.OrderChestnyZnak(ocz_id) NOT NULL,
	body_text          NVARCHAR(MAX) NOT NULL,
	signature_text     NVARCHAR(MAX) NOT NULL,
	create_dt          DATETIME2(0) NOT NULL,
	employee_id        INT NOT NULL,
	count_send         SMALLINT NOT NULL,
	error_desc         VARCHAR(900) NULL,
	error_dt           DATETIME2(0) NULL,
	fabricator_id      INT NULL CONSTRAINT [FK_OrderChestnyZnakSign_fabricator_id] FOREIGN KEY REFERENCES Settings.Fabricators(fabricator_id)
)
