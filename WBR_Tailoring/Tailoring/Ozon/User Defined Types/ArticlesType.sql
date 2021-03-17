CREATE TYPE [Ozon].[ArticlesType] AS TABLE
(
	id INT IDENTITY(1, 1) NOT NULL,
	ean VARCHAR(14),
	art VARCHAR(75),
	ozon_id INT,
	ozon_fbo_id INT,
	ozon_fbs_id INT,
	price_with_vat DECIMAL(9, 2)
)
GO

GRANT EXECUTE
    ON TYPE::[Ozon].[ArticlesType] TO PUBLIC;
GO