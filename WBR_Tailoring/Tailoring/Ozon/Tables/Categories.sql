CREATE TABLE [Ozon].[Categories]
(
	category_id             BIGINT CONSTRAINT [PK_Ozon_Categories] PRIMARY KEY CLUSTERED NOT NULL,
	category_parrent_id     BIGINT NULL,
	category_name           VARCHAR(100) NOT NULL,
	is_deleted              BIT NOT NULL,
	dt                      DATETIME2(0) NOT NULL
)
