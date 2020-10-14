CREATE TABLE [Products].[ProdArticleSyncStatus]
(
	pass_id TINYINT CONSTRAINT [PK_ProdArticleSyncStatus] PRIMARY KEY CLUSTERED NOT NULL,
	pass_name VARCHAR(50) NOT NULL,
	employee_id INT NOT NULL,
	dt DATETIME2(0) NOT NULL
)
