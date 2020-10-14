CREATE TABLE [Products].[ClothingZone]
(
	cz_id           INT IDENTITY(1, 1) CONSTRAINT [PK_ClothingZone] PRIMARY KEY CLUSTERED NOT NULL,
	cz_name         VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL
)