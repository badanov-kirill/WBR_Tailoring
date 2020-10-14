CREATE TABLE [Products].[Content]
(
	contents_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Content] PRIMARY KEY CLUSTERED NOT NULL,
	contents_name     VARCHAR(100) NOT NULL,
	dt                dbo.SECONDSTIME NOT NULL,
	employee_id       INT NOT NULL,
	is_deleted        BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Content_contents_name] ON Products.Content(contents_name) ON [Indexes] 
GO