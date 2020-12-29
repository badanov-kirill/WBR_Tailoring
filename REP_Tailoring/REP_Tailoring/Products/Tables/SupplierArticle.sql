CREATE TABLE [Products].[SupplierArticle]
(
	sa_id INT IDENTITY(1,1) CONSTRAINT [PK_SupplierArticle] PRIMARY KEY CLUSTERED NOT NULL,
	sa_name VARCHAR(36) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SupplierArticle_sa_name] ON Products.SupplierArticle(sa_name) INCLUDE(sa_id) ON [Indexes]