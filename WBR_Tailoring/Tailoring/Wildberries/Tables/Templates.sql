CREATE TABLE [Wildberries].[Templates]
(
	template_id INT CONSTRAINT [PK_Teplates] PRIMARY KEY CLUSTERED NOT NULL,
	template_name VARCHAR(200) NOT NULL,
	id_deleted BIT NOT NULL,
	dt DATETIME2(0) NOT NULL
)
