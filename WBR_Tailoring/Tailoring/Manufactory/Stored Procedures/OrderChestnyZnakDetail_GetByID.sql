CREATE PROCEDURE [Manufactory].[OrderChestnyZnakDetail_GetByID]
	@ocz_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	an.art_name,
			sj.subject_name,
			pa.sa + pan.sa sa,
			ts.ts_name,
			oczd.ean,
			oczd.cnt,
			spcvt.spcv_id,
			oczd.oczd_id
	FROM	Manufactory.OrderChestnyZnakDetail oczd   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = oczd.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id
	WHERE	oczd.ocz_id = @ocz_id
	ORDER BY
		pan.pan_id,
		ts.visible_queue,
		ts.ts_name