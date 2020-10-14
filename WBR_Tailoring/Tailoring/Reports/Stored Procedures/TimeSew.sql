CREATE PROCEDURE [Reports].[TimeSew]
	@office_id INT = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	os.office_name,
			sj.subject_name,
			s.sa,
			pa.sa + pan.sa color_sa,
			CAST(c.plan_start_dt AS DATETIME) plan_start_dt,
			CAST(c.closing_dt AS DATETIME) closing_dt,
			CAST(puc.packing_dt AS DATETIME) dt,
			puc.product_unic_code
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	puc.packing_dt IS NOT NULL
			AND (@office_id IS NULL OR c.office_id = @office_id)
			AND	c.plan_year = @plan_year
			AND	c.plan_month = @plan_month 
