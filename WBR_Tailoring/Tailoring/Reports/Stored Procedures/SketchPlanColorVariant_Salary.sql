CREATE PROCEDURE [Reports].[SketchPlanColorVariant_Salary]
	@start_dt DATETIME2(0),
	@finish_dt DATETIME2(0)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	SELECT	s.sketch_id,
			sj.subject_name,
			an.art_name,
			pa.sa + pan.sa     sa,
			pan.nm_id,
			os.office_name     sew_office_name,
			spcv.qty,
			v.plan_cnt,
			v.in_job_cnt,
			vsts.operation_cnt,
			v.in_job_cnt * vsts.operation_cnt operation_need_cnt,
			vsts.plan_cnt operation_plan_cnt,
			vsts.close_cnt operation_close_cnt,
			vsts.operation_salary operation_salary_cnt,
			vsts.amount_salary,
			spcv.spcv_id,
			CAST(spcv.fist_package_dt AS DATETIME) fist_package_dt
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	(SELECT	spcvt.spcv_id,
			    	     	 		SUM(spcvt.cnt) plan_cnt,
			    	     	 		SUM(spcvt.cut_cnt_for_job) in_job_cnt
			    	     	 FROM	Planing.SketchPlanColorVariantTS spcvt
			    	     	 GROUP BY
			    	     	 	spcvt.spcv_id)v
				ON	v.spcv_id = spcv.spcv_id   
			LEFT JOIN	(SELECT	sts.spcv_id,
			    	    	 		COUNT(DISTINCT sts.sts_id) operation_cnt,
			    	    	 		SUM(stsj.plan_cnt) plan_cnt,
			    	    	 		SUM(stsj.close_cnt) close_cnt,
			    	    	 		SUM(vs.operation_salary) operation_salary,
			    	    	 		SUM(vs.amount_salary) amount_salary
			    	    	 FROM	Manufactory.SPCV_TechnologicalSequence sts   
			    	    	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
			    	    	 			ON	stsj.sts_id = sts.sts_id     
			    	    	 		LEFT JOIN	(SELECT	stsjis.stsj_id,
			    	    	 		    	    	 		SUM(stsjis.cnt) operation_salary,
			    	    	 		    	    	 		SUM(stsjis.amount) amount_salary
			    	    	 		    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
			    	    	 		    	    	 GROUP BY
			    	    	 		    	    	 	stsjis.stsj_id)vs
			    	    	 			ON	vs.stsj_id = stsj.stsj_id
			    	    	 GROUP BY
			    	    	 	sts.spcv_id)vsts
				ON	vsts.spcv_id = spcv.spcv_id
	WHERE	spcv.fist_package_dt >= @start_dt
			AND	spcv.fist_package_dt <= @finish_dt