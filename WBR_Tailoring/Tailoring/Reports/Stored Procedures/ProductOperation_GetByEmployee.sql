CREATE PROCEDURE [Reports].[ProductOperation_GetByEmployee]
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	o.operation_name,
			sj.subject_name,
			pt.pt_name,
			pa.sa + pan.sa sa,
			CAST(CAST(po.dt AS DATE) AS DATETIME) day_dt,
			COUNT(DISTINCT po.product_unic_code) cnt_oper
	FROM	Manufactory.ProductOperations po   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = po.operation_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = po.product_unic_code   
			INNER JOIN	Products.ProductType pt
				ON	pt.pt_id = puc.pt_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	po.dt >= @start_dt
			AND	po.dt <= @finish_dt
			AND	po.employee_id = @employee_id
	GROUP BY
		o.operation_name,
		sj.subject_name,
		pt.pt_name,
		pa.sa + pan.sa,
		CAST(po.dt AS DATE)