CREATE PROCEDURE [Reports].[ProductOperation_GetByEmployeeDublePrint]
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	;WITH cte_Target AS (
		SELECT	po.product_unic_code
		FROM	Manufactory.ProductOperations po
		WHERE	po.dt >= @start_dt
				AND	po.dt <= @finish_dt
				AND	po.employee_id = @employee_id
				AND	po.operation_id = 8
		GROUP BY
			po.product_unic_code
		HAVING
			COUNT(po.po_id) > 1
	)	
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
			INNER JOIN	cte_target cte
				ON	cte.product_unic_code = po.product_unic_code
	WHERE	po.dt >= @start_dt
			AND	po.dt <= @finish_dt
			AND	po.employee_id = @employee_id
	ORDER BY
		po.product_unic_code,
		po.po_id