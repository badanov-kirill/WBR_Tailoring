CREATE TABLE [Products].[TPGroup]
(
	tpgroup_id       SMALLINT IDENTITY(1, 1) CONSTRAINT [PK_TPGroup] PRIMARY KEY CLUSTERED NOT NULL,
	tpgroup_name     VARCHAR(100) NOT NULL,
	erp_id           INT NOT NULL
)
