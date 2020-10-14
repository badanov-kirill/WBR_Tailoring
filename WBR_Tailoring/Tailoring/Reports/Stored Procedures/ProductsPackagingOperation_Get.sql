CREATE PROCEDURE [Reports].[ProductsPackagingOperation_Get]
	@start_dt dbo.SECONDSTIME,
	@finish_dt dbo.SECONDSTIME,
	@cutting_office_id INT = NULL,
	@operation_office_id INT = NULL,
	@employee_id INT = NULL
AS
	DECLARE @packaging_operation SMALLINT = 8
	
	SELECT	po.product_unic_code,
			os.office_name                   cutting_office_name,
			os2.office_name                  operation_office_name,
			po.employee_id,
			pa.sa + pan.sa                   sa,
			an.art_name,
			sj.subject_name,
			CAST(MIN(po.dt) AS DATETIME)     dt,
			CAST(CAST(MIN(po.dt) AS DATE) AS DATETIME) day_dt,
			b.brand_name
	FROM	Manufactory.ProductOperations po   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = po.product_unic_code   
			LEFT JOIN	Manufactory.Cutting c				   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id   
				ON	c.cutting_id = puc.cutting_id
			INNER JOIN	Settings.OfficeSetting os2
				ON	os2.office_id = po.office_id   
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
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
			INNER JOIN Products.Brand b 
				ON b.brand_id = pa.brand_id
	WHERE	po.operation_id = @packaging_operation
			AND	po.dt >= @start_dt
			AND	po.dt <= @finish_dt
			AND	(@cutting_office_id IS NULL OR c.office_id = @cutting_office_id)
			AND	(@operation_office_id IS NULL OR po.office_id = @operation_office_id)
			AND	(@employee_id IS NULL OR po.employee_id = @employee_id)
			AND po.is_uniq = 1
	GROUP BY
		po.product_unic_code,
		os.office_name,
		os2.office_name,
		po.employee_id,
		pa.sa + pan.sa,
		an.art_name,
		sj.subject_name,
		b.brand_name