CREATE TABLE [Products].[Constructor]
(
	constructor_employee_id     INT CONSTRAINT [PK_Constructor] PRIMARY KEY CLUSTERED NOT NULL,
	dt                          dbo.SECONDSTIME NOT NULL,
	employee_id                 INT NOT NULL
)