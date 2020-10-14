CREATE TABLE [Settings].[MasterEmployee]
(
	master_employee_id     INT NOT NULL,
	employee_id            INT NOT NULL,
	dt                     DATETIME2(0) NOT NULL,
	CONSTRAINT [PK_MasterEmployee] PRIMARY KEY CLUSTERED(master_employee_id, employee_id)
)
