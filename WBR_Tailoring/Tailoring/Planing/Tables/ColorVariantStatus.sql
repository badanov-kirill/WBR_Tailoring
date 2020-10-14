CREATE TABLE [Planing].[ColorVariantStatus]
(
	cvs_id          TINYINT CONSTRAINT [PK_ColorVariantStatus] PRIMARY KEY CLUSTERED NOT NULL,
	cvs_name        VARCHAR(50) NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	employee_id     INT NOT NULL
)