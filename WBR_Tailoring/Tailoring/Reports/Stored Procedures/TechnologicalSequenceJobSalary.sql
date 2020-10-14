CREATE PROCEDURE [Reports].[TechnologicalSequenceJobSalary]
	@salary_year SMALLINT,
	@salary_month TINYINT,
	@employee_id INT = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET ARITHABORT ON
	
	SELECT	stsj.job_employee_id,
			es.employee_name,
			stsjis.cnt,
			stsjis.amount,
			sts.operation_time * stsjis.cnt job_time,
			pa.sa + pan.sa        sa,
			an.art_name,
			ts.ts_name,
			ta.ta_name            ta,
			e.element_name        element,
			eq.equipment_name     equipment,
			sts.discharge_id,
			os.office_name        sew_office_name
	FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis   
			INNER JOIN	Salary.SalaryPeriod sp
				ON	sp.salary_period_id = stsjis.salary_period_id   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = stsjis.stsj_id   
			INNER JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = stsj.job_employee_id   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = stsj.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = sts.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = sts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = sts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = sts.equipment_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id
	WHERE	sp.salary_year = @salary_year
			AND	sp.salary_month = @salary_month
			AND	(@employee_id IS NULL OR stsj.job_employee_id = @employee_id)
			AND	(@office_id IS NULL OR es.office_id = @office_id)
	OPTION(RECOMPILE)