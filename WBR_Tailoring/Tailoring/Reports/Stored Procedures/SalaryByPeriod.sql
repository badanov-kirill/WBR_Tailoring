CREATE PROCEDURE [Reports].[SalaryByPeriod]
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
	
	DECLARE @dt_start DATETIME2(0) = DATEFROMPARTS(@salary_period_year, @salary_period_mont, 1)
	DECLARE @dt_finish DATETIME2(0) = DATEADD(MONTH, 1, @dt_start) 
	
	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_rework TINYINT = 16 --Доработан конструктором
	
	DECLARE @tab_brigade TABLE (employee_id INT PRIMARY  KEY CLUSTERED, brigade_id INT)
	
	INSERT INTO @tab_brigade
		(
			employee_id,
			brigade_id
		)
	SELECT	TOP(1) WITH TIES bed.employee_id,
			bed.brigade_id
	FROM	Settings.BrigadeEmployeeDate bed
	WHERE	bed.begin_dt <= CAST(@dt_start AS DATE)
	ORDER BY
		ROW_NUMBER() OVER(PARTITION BY bed.employee_id ORDER BY bed.begin_dt DESC)
	
	
	SELECT	stsj.job_employee_id,
			spcv.sew_office_id     office_id,
			sts.discharge_id,
			tb.brigade_id,
			CAST(SUM(stsjis.cnt * sts.operation_time) AS INT) job_second,
			SUM(stsjis.amount)     amount			
	FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = stsjis.stsj_id   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = sts.spcv_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = stsj.job_employee_id
	WHERE	stsjis.salary_period_id = @salary_period_id
	GROUP BY
		stsj.job_employee_id,
		spcv.sew_office_id,
		sts.discharge_id,
		tb.brigade_id
	
	SELECT	es.department_id,
			cae.employee_id,
			c.office_id,
			ct.ct_id,
			ct.ct_name,
			tb.brigade_id,
			SUM(ca.actual_count * c.perimeter * ISNULL(pan.cutting_degree_difficulty, 1) / oa_cnt.cnt_empl) AS sum_perimetr,
			SUM(ca.actual_count * c.perimeter * ISNULL(pan.cutting_degree_difficulty, 1) * c.cutting_tariff / oa_cnt.cnt_empl) sum_amount
	FROM	Manufactory.Cutting c   
			INNER JOIN	Manufactory.CuttingActual ca
				ON	ca.cutting_id = c.cutting_id   
			INNER JOIN	Manufactory.CuttingActualEmployee cae
				ON	cae.ca_id = ca.ca_id   
			INNER JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = cae.employee_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = c.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Settings.OfficeSetting bo
				ON	bo.office_id = c.office_id 
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = cae.employee_id 
			OUTER 	APPLY (
			      		SELECT	COUNT(cae2.employee_id) cnt_empl
			      		FROM	Manufactory.CuttingActualEmployee cae2
			      		WHERE	cae2.ca_id = ca.ca_id
			      	) oa_cnt
	WHERE	ca.dt >= @dt_start
			AND	ca.dt < @dt_finish
	GROUP BY
		es.department_id,
		cae.employee_id,
		c.office_id,
		ct.ct_id,
		ct.ct_name,
		tb.brigade_id
	
	SELECT	s.constructor_employee_id employee_id,
			es.office_id,
			tb.brigade_id,
			SUM(CASE WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NULL THEN s.constructor_coeffecient ELSE 0 END) new_construction,
			SUM(CASE WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NOT NULL THEN s.constructor_coeffecient ELSE 0 END) 
			new_construction_from_base,
			SUM(CASE WHEN ss.ss_id = @state_complite_constructor_rework THEN s.constructor_coeffecient ELSE 0 END) rework
	FROM	History.SketchStatus ss   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = ss.sketch_id   
			INNER JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = s.employee_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = s.constructor_employee_id
	WHERE	ss.dt >= @dt_start
			AND	ss.dt < @dt_finish
			AND	ss.ss_id     IN (@state_complite_constructor, @state_complite_constructor_rework)
	GROUP BY
		s.constructor_employee_id,
		es.office_id,
		tb.brigade_id
	
	SELECT	po.employee_id,
			po.office_id,
			puc2.pt_id,
			s.subject_id,
			tb.brigade_id,
			SUM(CASE WHEN po.operation_id IN (1, 2, 3, 4) THEN 1 ELSE 0 END) controlling,
			SUM(CASE WHEN po.operation_id = 5 THEN 1 ELSE 0 END) controlling_pre_special_equipment,
			SUM(CASE WHEN po.operation_id = 6 THEN 1 ELSE 0 END) controlling_after_special_equipment,
			SUM(CASE WHEN po.operation_id = 8 AND puc.product_unic_code IS NOT NULL THEN 1 ELSE 0 END) packaging,
			SUM(CASE WHEN po.operation_id = 10 THEN 1 ELSE 0 END) repaired
	FROM	Manufactory.ProductOperations po   
			LEFT JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = po.product_unic_code
				AND	puc.operation_id = po.operation_id
				AND	puc.dt = po.dt   
			INNER JOIN	Manufactory.ProductUnicCode puc2
				ON	puc2.product_unic_code = po.product_unic_code   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc2.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = po.employee_id  
	WHERE	po.dt >= @dt_start
			AND	po.dt < @dt_finish
			AND	po.operation_id IN (1, 2, 3, 4, 5, 6, 8, 10)
			AND po.is_uniq = 1
	GROUP BY
		po.employee_id,
		po.office_id,
		puc2.pt_id,
		s.subject_id,
		tb.brigade_id
	
	SELECT	spcv.master_employee_id,
			es.office_id,
			tb.brigade_id,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN oat.operation_time ELSE 0 END) hour_on_time,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN oat.operation_time ELSE 0 END) hour_expired,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) <= spcv.deadline_package_dt OR spcv.deadline_package_dt IS NULL THEN 1 ELSE 0 END) cnt_on_time,
			SUM(CASE WHEN CAST(puc.packing_dt AS DATE) > spcv.deadline_package_dt THEN 1 ELSE 0 END) cnt_expired
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN Settings.EmployeeSetting es
				ON spcv.master_employee_id = es.employee_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = spcv.master_employee_id
			OUTER APPLY (
			      	SELECT	SUM(sts.operation_time) / 3600 operation_time
			      	FROM	Manufactory.SPCV_TechnologicalSequence sts
			      	WHERE	sts.spcv_id = spcv.spcv_id
			      ) oat
			
	WHERE	spcv.master_employee_id IS NOT NULL
			AND	puc.packing_dt >= @dt_start
			AND	puc.packing_dt < @dt_finish
			AND	puc.operation_id IN (8, 3, 4, 1, 6)
	GROUP BY
		spcv.master_employee_id,
		es.office_id,
		tb.brigade_id
	
	SELECT	ts.pattern_employee_id,
			ts.office_id,
			tb.brigade_id,
			SUM(s.pattern_perimeter) pattern_perimeter
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = ts.pattern_employee_id
	WHERE	ts.pattern_end_of_work_dt >= @dt_start
			AND	ts.pattern_end_of_work_dt < @dt_finish
			AND	s.pattern_perimeter != 0
			AND	ts.is_stm = 0
			AND	ts.is_deleted = 0
	GROUP BY
		ts.pattern_employee_id,
		ts.office_id,
		tb.brigade_id
	
	
	SELECT	ts.cut_employee_id,
			ts.office_id,
			s.ct_id,
			tb.brigade_id,
			SUM(s.cut_perimeter) cut_perimeter
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = ts.cut_employee_id
	WHERE	ts.cut_end_of_work_dt >= @dt_start
			AND	ts.cut_end_of_work_dt <= @dt_finish
			AND	s.cut_perimeter != 0
			AND	ts.is_stm = 0
			AND	ts.is_deleted = 0
	GROUP BY
		ts.cut_employee_id,
		ts.office_id,
		s.ct_id,
		tb.brigade_id
	
	SELECT	tsew.sew_employee_id,
			tsew.office_id,
			tsew.ct_id,
			tb.brigade_id,
			SUM(tss.stream_time) stream_time
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.sample_id = s.sample_id   
			INNER JOIN	Manufactory.TaskSew tsew
				ON	tsew.ts_id = tss.ts_id
			LEFT JOIN @tab_brigade tb 
				ON tb.employee_id = tsew.sew_employee_id
	WHERE	tss.close_dt >= @dt_start
			AND	tss.close_dt <= @dt_finish
			AND	tss.stream_time > 0
	GROUP BY
		tsew.sew_employee_id,
		tsew.office_id,
		tsew.ct_id,
		tss.is_mixed,
		tb.brigade_id