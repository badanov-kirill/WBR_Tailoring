CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sp.sp_id,
			ps.ps_name,
			sp.create_employee_id,
			CAST(sp.create_dt AS DATETIME) create_dt,
			sp.comment,
			sp.plan_year,
			sp.plan_month,
			spcv.spcv_name,
			cvs.cvs_name,
			spcv.qty,
			spcv.is_deleted,
			spcv.comment                    cv_comment,
			spcv.corrected_qty,
			spcv.pan_id,
			pa.sa + pan.sa                  sa,
			os.office_name                  sew_office_name,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			spcv.cost_plan_year,
			spcv.cost_plan_month,
			spcv.spcv_id,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			ISNULL(oa_pac.packaging, 0)     packaging,
			pan.nm_id,
			cd.covering_id,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			CAST(cov.cost_dt AS DATETIME) cost_dt,
			coll.collection_name,
			CAST(sp.plan_sew_dt AS DATETIME) plan_sew_dt,
			spcvc.cost_rm,
			spcvc.cost_work,
			spcvc.cost_fix,
			spcvc.cost_add,
			spcvc.price_ru,
			spcvc.cost_cutting,
			spcvc.cost_rm_without_nds,
			sl.season_local_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			LEFT JOIN	Planing.CoveringDetail cd   
			INNER JOIN	Planing.Covering cov
				ON	cov.covering_id = cd.covering_id
				ON	cd.spcv_id = spcv.spcv_id   
			LEFT JOIN	Products.[Collection] coll
				ON	coll.collection_id = pa.collection_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCost spcvc
				ON	spcvc.spcv_id = spcv.spcv_id 
			LEFT JOIN Products.SeasonLocal sl
				ON sl.season_local_id = sp.season_local_id  
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
	WHERE	sp.sketch_id = @sketch_id
	