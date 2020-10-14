CREATE TABLE [Settings].[StringValue]
(
	code            CHAR(3) CONSTRAINT [PK_StringValue] PRIMARY KEY CLUSTERED NOT NULL,
	svalue          VARCHAR(200) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)
