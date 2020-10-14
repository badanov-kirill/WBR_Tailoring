CREATE PROCEDURE [Reports].[SketchPlanColorVariant_SalaryBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sts.operation_range,
			ta.ta_name                ta,
			e.element_name            element,
			eq.equipment_name         equipment,
			sts.operation_value,
			sts.rotaiting,
			sts.dc_coefficient,
			cd.comment,
			sts.discharge_id,
			sts.operation_time,
			vsts.plan_cnt             operation_plan_cnt,
			vsts.close_cnt            operation_close_cnt,
			vsts.operation_salary     operation_salary_cnt,
			vsts.amount_salary,
			sts.sts_id
	FROM	Manufactory.SPCV_TechnologicalSequence sts   
			INNER JOIN	Technology.CommentDict cd
				ON	cd.comment_id = sts.comment_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = sts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = sts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = sts.equipment_id   
			LEFT JOIN	(SELECT	stsj.sts_id,
			    	    	 		SUM(stsj.plan_cnt) plan_cnt,
			    	    	 		SUM(stsj.close_cnt) close_cnt,
			    	    	 		SUM(vs.operation_salary) operation_salary,
			    	    	 		SUM(vs.amount_salary) amount_salary
			    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			    	    	 		LEFT JOIN	(SELECT	stsjis.stsj_id,
			    	    	 		    	    	 		SUM(stsjis.cnt) operation_salary,
			    	    	 		    	    	 		SUM(stsjis.amount) amount_salary
			    	    	 		    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
			    	    	 		    	    	 GROUP BY
			    	    	 		    	    	 	stsjis.stsj_id)vs
			    	    	 			ON	vs.stsj_id = stsj.stsj_id
			    	    	 GROUP BY
			    	    	 	stsj.sts_id)vsts
				ON	vsts.sts_id = sts.sts_id
	WHERE	sts.spcv_id = @spcv_id