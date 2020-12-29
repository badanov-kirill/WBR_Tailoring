CREATE PROCEDURE [Reports].[LastPackagingOperation]
	@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @packaging_operation SMALLINT = 8
	DECLARE @dt dbo.SECONDSTIME = DATEADD(DAY, -30, GETDATE())
	
	SELECT	ts.ts_name,
			COUNT(DISTINCT puc2.product_unic_code) cnt
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants2
				ON	pants2.pan_id = pan.pan_id   
			INNER JOIN	Manufactory.ProductUnicCode puc2
				ON	puc2.pants_id = pants2.pants_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants2.ts_id   
	WHERE	puc.product_unic_code = @product_unic_code
			AND	puc2.operation_id = @packaging_operation
	GROUP BY
		ts.ts_name