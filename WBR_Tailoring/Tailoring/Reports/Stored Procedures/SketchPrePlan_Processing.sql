CREATE PROCEDURE [Reports].[SketchPrePlan_Processing]
	@brand_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@subject_id INT = NULL,
	@sa VARCHAR(36) = NULL,
	@ct_id INT = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spp.spp_id,
			spp.season_model_year,
			sl.season_local_name,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			sn.season_name,
			os.office_name,
			spps.spps_name,
			CAST(spp.create_dt AS DATETIME) create_dt,
			spp.plan_qty,
			spp.cv_qty,
			CAST(spp.plan_dt AS DATETIME) plan_dt,
			v.spcv_qty,
			v.cv_qty fact_cv_qty,
			v.ps_name,
			v.qty_create,
			v.qty_work,
			ct.ct_name,
			s.pre_time_tech_seq,
			v_ts.operation_time,
			s.loops, 
			s.buttons
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Planing.SketchPrePlanStatus spps
				ON	spps.spps_id = spp.spps_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spp.sew_office_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = spp.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = spp.season_local_id  
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id 
			LEFT JOIN	(SELECT	sp.sp_id,
			    	    	 		sp.spp_id,
			    	    	 		SUM(ISNULL(spcv.corrected_qty, spcv.qty)) spcv_qty,
			    	    	 		COUNT(spcv.spcv_id) cv_qty,
			    	    	 		MAX(ps.ps_name) ps_name,
			    	    	 		SUM(CASE WHEN spcv.cvs_id = 1 THEN ISNULL(spcv.corrected_qty, spcv.qty) ELSE 0 END) qty_create,
			    	    	 		SUM(CASE WHEN spcv.cvs_id > 1 THEN ISNULL(spcv.corrected_qty, spcv.qty) ELSE 0 END) qty_work
			    	    	 FROM	Planing.SketchPlan sp   
			    	    	 		LEFT JOIN	Planing.SketchPlanColorVariant spcv
			    	    	 			ON	spcv.sp_id = sp.sp_id
			    	    	 			AND	spcv.is_deleted = 0   
			    	    	 		INNER JOIN	Planing.PlanStatus ps
			    	    	 			ON	ps.ps_id = sp.ps_id
			    	    	 WHERE	sp.spp_id IS NOT NULL
			    	    	 GROUP BY
			    	    	 	sp.sp_id,
			    	    	 	sp.spp_id)v
				ON	v.spp_id = spp.spp_id
			LEFT JOIN (
						SELECT ts.sketch_id, SUM(ts.operation_time) operation_time
						FROM Products.TechnologicalSequence ts
						GROUP BY ts.sketch_id	
			) v_ts ON v_ts.sketch_id = s.sketch_id
	WHERE	spp.spps_id IN (1, 2)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@sa IS NULL OR s.sa LIKE '%' + @sa + '%')
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@season_local_id IS NULL OR spp.season_local_id = @season_local_id)
			AND	(@model_year IS NULL OR spp.season_model_year = @model_year)
			AND	(@office_id IS NULL OR spp.sew_office_id = @office_id)