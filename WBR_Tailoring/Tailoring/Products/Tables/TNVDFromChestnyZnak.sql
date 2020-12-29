CREATE TABLE [Products].[TNVDFromChestnyZnak]
(
	tnved_id INT CONSTRAINT [FK_TNVDFromChestnyZnak_tnved_id] FOREIGN KEY REFERENCES Products.TNVED(tnved_id) NOT NULL,
	start_dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL,
	dt	DATETIME2(0) NOT NULL,	
	CONSTRAINT [PK_TNVDFromChestnyZnak] PRIMARY KEY CLUSTERED (tnved_id)
)