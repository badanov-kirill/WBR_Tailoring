CREATE TABLE [Products].[Brands]
(
	brand_id SMALLINT IDENTITY(1,1) CONSTRAINT [PK_PrimaryKey_Brands] PRIMARY KEY CLUSTERED NOT NULL,
	brand_name VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Brands_brand_name] ON Products.Brands(brand_name) INCLUDE(brand_id) ON [Indexes]