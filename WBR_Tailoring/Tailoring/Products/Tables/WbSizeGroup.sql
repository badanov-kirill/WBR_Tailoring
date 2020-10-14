CREATE TABLE [Products].[WbSizeGroup]
(
	wb_size_group_id              INT CONSTRAINT PK_WbSizeGroup PRIMARY KEY CLUSTERED NOT NULL,
	wb_size_group_description     VARCHAR(900) NOT NULL,
	erp_id                        INT NOT NULL
)