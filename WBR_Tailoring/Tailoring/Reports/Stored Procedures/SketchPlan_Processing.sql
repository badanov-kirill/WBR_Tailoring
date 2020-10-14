CREATE PROCEDURE [Reports].[SketchPlan_Processing]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v.spp_id,
			v.sp_id,
			v.sketch_id,
			spcv.spcv_id,
			v.season_model_year,
			sl.season_local_name,
			b.brand_name,
			sj.subject_name,
			an.art_name,
			sn.season_name,
			ISNULL(os2.office_name, os.office_name) office_name,
			CAST(v.create_dt AS DATETIME) create_dt,
			v.plan_qty,
			v.cv_qty,
			CAST(v.plan_dt AS DATETIME)     plan_dt,
			ct.ct_name,
			ps.ps_name,
			spcv.comment                    cv_comment,
			ISNULL(spcv.corrected_qty, spcv.qty) spcv_qty,
			pa.sa + pan.sa                  sa,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			spcv.cost_plan_year,
			spcv.cost_plan_month,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			ISNULL(oa_pac.packaging, 0)     packaging,
			pan.nm_id,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			spcvc.cost_rm,
			spcvc.cost_work,
			spcvc.cost_fix,
			spcvc.cost_add,
			spcvc.price_ru,
			spcvc.cost_cutting,
			cvs.cvs_name,
			CASE 
			     WHEN v.spp_id IS NULL THEN 0
			     ELSE 1
			END                             is_pre_plan
	FROM	(SELECT	spp.spp_id,
	    	 		sp.sp_id,
	    	 		spp.sketch_id,
	    	 		spp.sew_office_id,
	    	 		spp.plan_dt,
	    	 		spp.plan_qty,
	    	 		spp.cv_qty,
	    	 		spp.season_local_id,
	    	 		spp.season_model_year,
	    	 		spp.create_dt,
	    	 		sp.ps_id
	    	 FROM	Planing.SketchPrePlan spp   
	    	 		INNER JOIN	Products.Sketch s
	    	 			ON	s.sketch_id = spp.sketch_id   
	    	 		LEFT JOIN	Planing.SketchPlan sp
	    	 			ON	sp.spp_id = spp.spp_id
	    	 			AND sp.ps_id != 3
	    	 WHERE	spp.plan_dt >= @start_dt
	    	 		AND	spp.plan_dt <= @finish_dt
	    	 		AND	spp.spps_id IN (1, 2)
	    	UNION ALL
	    	SELECT	NULL,
	    			sp.sp_id,
	    			sp.sketch_id,
	    			sp.sew_office_id,
	    			sp.plan_sew_dt,
	    			sp.plan_qty,
	    			sp.cv_qty,
	    			sp.season_local_id,
	    			sp.plan_year,
	    			sp.create_dt,
	    			sp.ps_id
	    	FROM	Planing.SketchPlan sp
	    	WHERE	sp.spp_id IS NULL
	    			AND	sp.plan_sew_dt >= @start_dt
	    			AND	sp.plan_sew_dt <= @finish_dt
					AND sp.ps_id != 3)v   
			LEFT JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = v.ps_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = v.sew_office_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = v.season_local_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCost spcvc
				ON	spcvc.spcv_id = spcv.spcv_id
				ON	spcv.sp_id = v.sp_id  AND spcv.is_deleted = 0 
			LEFT JOIN Settings.OfficeSetting os2
				ON os2.office_id = spcv.sew_office_id
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count
			      	FROM	Manufactory.CuttingActual ca   
			      			INNER JOIN	Manufactory.Cutting c
			      				ON	c.cutting_id = ca.cutting_id   
			      			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			      				ON	spcvt.spcvts_id = c.spcvts_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_ac
			OUTER APPLY (
	      			SELECT	SUM(1) packaging
	      			FROM	Manufactory.ProductUnicCode puc   
	      					INNER JOIN	Manufactory.Cutting c2
	      						ON	c2.cutting_id = puc.cutting_id   
	      					INNER JOIN	Planing.SketchPlanColorVariantTS spcvt2
	      						ON	spcvt2.spcvts_id = c2.spcvts_id
	      			WHERE	spcvt2.spcv_id = spcv.spcv_id
	      					AND	puc.operation_id = 8
				  )                                 oa_pac