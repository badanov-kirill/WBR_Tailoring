CREATE TABLE [Products].[Collection]
(
	collection_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Collection] PRIMARY KEY CLUSTERED NOT NULL,
	collection_name     VARCHAR(150) NOT NULL,
	employee_id         INT NOT NULL,
	dt                  dbo.SECONDSTIME NOT NULL,
	is_deleted          BIT NOT NULL,
	collection_year     SMALLINT NULL,
	erp_id              INT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Collection_collection_name]  ON Products.[Collection](collection_name) WHERE is_deleted = 0 ON [Indexes]
GO