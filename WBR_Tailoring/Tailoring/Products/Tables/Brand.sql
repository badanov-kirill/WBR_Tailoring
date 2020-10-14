CREATE TABLE [Products].[Brand]
(
	brand_id        INT IDENTITY(1, 1) CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED NOT NULL,
	brand_name      VARCHAR(50) NOT NULL,
	employee_id     INT NOT NULL,
	dt              dbo.SECONDSTIME NOT NULL,
	erp_id          INT NOT NULL,
)

GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_Brand_brand_name] ON Products.Brand(brand_id) ON [Indexes]
GO