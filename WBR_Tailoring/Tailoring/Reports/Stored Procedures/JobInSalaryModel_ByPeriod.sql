CREATE PROCEDURE [Reports].[JobInSalaryModel_ByPeriod]
	@salary_period_year SMALLINT,
	@salary_period_mont TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @salary_period_id INT
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.salary_period_id IS NULL THEN 'Зарплатный период не существует'
	      	                   ELSE NULL
	      	              END,
			@salary_period_id = sp.salary_period_id
	FROM	Salary.SalaryPeriod sp
	WHERE	sp.salary_year = @salary_period_year
			AND	sp.salary_month = @salary_period_mont
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	s.sketch_id,
			b.brand_name,
			pa.sa + pan.sa                 sa,
			an.art_name,
			sj.subject_name,
			v.spcv_id,
			v.amount,
			spcvc.cost_rm,
			spcvc.cost_work,
			spcvc.cost_fix,
			spcvc.cost_add,
			spcvc.cost_cutting,
			ready.cnt_ready,
			v.amount / spcvc.cost_work     cnt_cost_work,
			oa_ac.actual_count cutting_count,
			os.office_name,
			ct.ct_name,
			v_op_time.operation_time
	FROM	(SELECT	sts.spcv_id,
	    	 		SUM(stsjis.amount) amount
	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis   
	    	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
	    	 			ON	stsj.stsj_id = stsjis.stsj_id   
	    	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
	    	 			ON	sts.sts_id = stsj.sts_id
	    	 WHERE	stsjis.salary_period_id = @salary_period_id
	    	 GROUP BY
	    	 	sts.spcv_id)v   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = v.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
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
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = spcv.sew_office_id  
			LEFT JOIN	Planing.SketchPlanColorVariantCost spcvc
				ON	spcvc.spcv_id = spcv.spcv_id 
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id  
			LEFT JOIN	(SELECT	spcvt.spcv_id,
			    	    	 		COUNT(1) cnt_ready
			    	    	 FROM	Manufactory.ProductUnicCode puc   
			    	    	 		INNER JOIN	Manufactory.Cutting c
			    	    	 			ON	c.cutting_id = puc.cutting_id   
			    	    	 		INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			    	    	 			ON	spcvt.spcvts_id = c.spcvts_id
			    	    	 WHERE	puc.operation_id IN (8, 4, 3, 1, 6)
			    	    	 GROUP BY
			    	    	 	spcvt.spcv_id)ready
				ON	ready.spcv_id = spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	ISNULL(SUM(ca.actual_count), 0) actual_count
			      	FROM	Planing.SketchPlanColorVariantTS spcvt   
			      			INNER JOIN	Manufactory.Cutting cut
			      				ON	cut.spcvts_id = spcvt.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_ac 
			LEFT JOIN (
			          	SELECT	sts.spcv_id,
			          			SUM(sts.operation_time) operation_time
			          	FROM	Manufactory.SPCV_TechnologicalSequence sts
			          	GROUP BY
			          		sts.spcv_id
			          )v_op_time ON v_op_time.spcv_id = v.spcv_id
