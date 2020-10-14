CREATE TABLE [Products].[Style]
(
	style_id        INT IDENTITY(1, 1) CONSTRAINT [PK_Style] PRIMARY KEY CLUSTERED NOT NULL,
	style_name      VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	is_deleted      BIT NOT NULL,
	erp_id          INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Style_style_name]  ON Products.Style(style_name)	WHERE is_deleted = 0	ON [Indexes]
GO