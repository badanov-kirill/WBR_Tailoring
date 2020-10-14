CREATE TABLE [Products].[ProductType]
(
	pt_id           TINYINT CONSTRAINT [PK_ProductType] PRIMARY KEY CLUSTERED NOT NULL,
	pt_name         VARCHAR(50) NOT NULL,
	pt_rate         DECIMAL(4, 2) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	work_time       INT NULL
)
