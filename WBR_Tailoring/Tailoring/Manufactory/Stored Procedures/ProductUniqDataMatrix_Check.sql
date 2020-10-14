CREATE PROCEDURE [Manufactory].[ProductUniqDataMatrix_Check]
	@product_uniq_data_martix_id INT,
	@product_unic_code INT
AS
	SET NOCOUNT ON
	
	DECLARE @error_text VARCHAR(MAX)
	
	IF ISNULL(@product_unic_code, 0) = 0
	BEGIN
	    RAISERROR('Не указан код продукта', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ISNULL(v.product_uniq_data_martix_id, 0) = 0 THEN 'Не указан уникальный код пакета'
	      	                   WHEN pudmpu.product_unic_code IS NOT NULL AND pudmpu.product_unic_code != @product_unic_code THEN 
	      	                        'Этот уникальный код пакета уже связан с изделием TLPR' + CAST(pudmpu.product_unic_code AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@product_uniq_data_martix_id))v(product_uniq_data_martix_id)   
			LEFT JOIN	Manufactory.ProductUniqDataMatrixProductUnic pudmpu
				ON	pudmpu.product_uniq_data_martix_id = v.product_uniq_data_martix_id
				
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END