CREATE TABLE [Products].[Apportionment]
(
	apportionment_id INT IDENTITY(1,1) CONSTRAINT [PK_Apportionment] PRIMARY KEY CLUSTERED NOT NULL,
	efficiency_perc TINYINT NULL,
	traverse_length SMALLINT NOT NULL,
	frame_width SMALLINT NOT NULL,
	dt DATETIME2(0) NOT NULL,
	employee_id INT NOT NULL
)
