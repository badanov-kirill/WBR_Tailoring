CREATE PROCEDURE [Manufactory].[Product_CuttingPreWriteOff_Get]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			sj.subject_name,
			b.brand_name,
			an.art_name,
			pa.sa + pan.sa               sa,
			spcv.spcv_id,
			ts.ts_name,
			puc.product_unic_code,
			spcv.sp_id,
			spcvt.spcvts_id,
			CAST(puc.dt AS DATETIME)     dt
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	puc.operation_id = 11
			AND	(@office_id IS NULL OR c.office_id = @office_id)
	ORDER BY
		an.art_name,
		spcv.spcv_id,
		ts_name