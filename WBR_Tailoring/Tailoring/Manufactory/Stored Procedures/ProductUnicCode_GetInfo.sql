CREATE PROCEDURE [Manufactory].[ProductUnicCode_GetInfo]
	@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	pa.sa + pan.sa     sa,
			pan.nm_id,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			ts.erp_id          ts_id,
			puc.operation_id,
			o.operation_name,
			CAST(ISNULL(spcv.deadline_package_dt, DATEADD(DAY, -7, sp.plan_sew_dt)) AS DATETIME) plan_sew_dt
	FROM	Manufactory.ProductUnicCode puc   
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
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = puc.operation_id   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id
				ON	spcv.spcv_id = spcvt.spcv_id
				ON	spcvt.spcvts_id = c.spcvts_id
	WHERE	puc.product_unic_code = @product_unic_code