CREATE PROCEDURE [Planing].[SketchPlanColorVariantCost_Get]
	@start_dt DATE,
	@finish_dt DATE,
	@brand_id INT = NULL
AS
	SET NOCOUNT ON
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa + pan.sa     sa,
			pan.nm_id,
			c.color_name,
			--ts.ts_name
			'' ts_name,
			oa_ac.actual_count,
			spcvc.cost_rm,
			spcvc.cost_rm_without_nds,
			spcvc.cost_work,
			spcvc.cost_fix,
			spcvc.cost_add,
			spcvc.price_ru,
			spcvc.cost_cutting,
			spcvc.create_dt,
			spcvc.cost_rm + spcvc.cost_work + spcvc.cost_fix + spcvc.cost_add + spcvc.cost_cutting cost,
			spcvc.cost_rm_without_nds + spcvc.cost_work + spcvc.cost_fix + spcvc.cost_add + spcvc.cost_cutting cost_without_nds,
			spcvcn.cutting_qty,
			spcvcn.cut_write_off,
			spcvcn.write_off,
			spcvcn.packaging,
			spcvcn.finished
	FROM	Planing.SketchPlanColorVariantCost spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcvc.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			--INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			--	ON	spcvt.spcv_id = spcv.spcv_id   
			--INNER JOIN	Products.TechSize ts
			--	ON	ts.ts_id = spcvt.ts_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCounter spcvcn
				ON	spcvcn.spcv_id = spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	ISNULL(SUM(ca.actual_count), 0) actual_count
			      	FROM	Manufactory.Cutting cut   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
								ON	cut.spcvts_id = spcvt.spcvts_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      )            oa_ac
	WHERE	spcvc.create_dt >= @start_dt
			AND	spcvc.create_dt <= @finish_dt
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)