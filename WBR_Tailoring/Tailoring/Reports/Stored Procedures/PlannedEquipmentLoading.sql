CREATE PROCEDURE [Reports].[PlannedEquipmentLoading]
	@office_id INT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	
	SELECT	an.art_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			spcv.spcv_id,
			ISNULL(oa_ca.cutting_qty, spcv.corrected_qty) qty,
			pa.sa + pan.sa     nm_sa,
			c.color_name       main_color,
			os.office_name     sew_office_name,
			eq.equipment_name,
			v.operation_time * ISNULL(oa_ca.cutting_qty, spcv.corrected_qty) / 60 operation_time_hour
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) cutting_qty
			      	FROM	Manufactory.Cutting cut   
			      			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			      				ON	spcvt.spcvts_id = cut.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_ca
	LEFT JOIN	(SELECT	tseq.sketch_id,
			    	  	 		tseq.equipment_id,
			    	  	 		SUM(tseq.operation_time) operation_time
			    	  	 FROM	Products.TechnologicalSequence tseq
			    	  	 GROUP BY
			    	  	 	tseq.sketch_id,
			    	  	 	tseq.equipment_id)v   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = v.equipment_id
				ON	v.sketch_id = s.sketch_id
	WHERE	spcv.cvs_id IN (@cv_status_placing, @cv_status_rm_issue)
			AND	(@office_id IS NULL OR spcv.sew_office_id = @office_id)
			AND	spcv.is_deleted = 0
	ORDER BY
		an.art_name,
		sp.sketch_id,
		spcv.spcv_id