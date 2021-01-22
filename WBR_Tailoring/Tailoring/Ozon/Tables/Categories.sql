CREATE TABLE [Ozon].[Categories]
(
	category_id             INT CONSTRAINT [PK_Ozon_Categories] PRIMARY KEY CLUSTERED NOT NULL,
	caregory_parrent_id     INT NULL,
	category_name           VARCHAR(100) NOT NULL,
	is_deleted              BIT NOT NULL,
	dt                      DATETIME2(0) NOT NULL
)
