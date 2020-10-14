CREATE TABLE [Products].[ConsistType]
(
	consist_type_id       INT IDENTITY(1, 1) CONSTRAINT [PK_ConsistType] PRIMARY KEY CLUSTERED NOT NULL,
	consist_type_name     VARCHAR(100) NOT NULL
)
