CREATE PROCEDURE [Reports].[ProductOperation_GetByID]
	@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	po.product_unic_code,
			o.operation_name,
			bo.office_name,
			po.employee_id,
			CAST(po.dt AS DATETIME)     dt,
			pan.nm_id,
			pa.sa + pan.sa              sa
	FROM	Manufactory.ProductOperations AS po   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = po.product_unic_code   
			INNER JOIN	Manufactory.Operation AS o
				ON	o.operation_id = po.operation_id   
			LEFT JOIN	Products.ProductType AS pt
				ON	pt.pt_id = puc.pt_id   
			INNER JOIN	Settings.OfficeSetting AS bo
				ON	bo.office_id = po.office_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
	WHERE	po.product_unic_code = @product_unic_code
	ORDER BY
		po.po_id