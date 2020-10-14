CREATE PROCEDURE [Manufactory].[TaskForTechnolog_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sample_id,
			s.sketch_id,
			s.task_sample_id,
			s.st_id,
			s.ts_id,
			s.ct_id,
			s.comment,
			s.sew_launch_dt,
			s.sew_launch_employee_id,
			s.pattern_perimeter,
			s.cut_perimeter
	INTO	#t
	FROM	Manufactory.[Sample] s
	WHERE	s.sketch_id = @sketch_id
			AND	s.is_deleted = 0
			AND s.st_id NOT IN (4, 5)
	
	SELECT	ts.task_sample_id,
			ts.qp_id,
			qp.qp_name,
			ts.ct_id,
			ct.ct_name,
			ts.office_id,
			ts.pattern_employee_id,
			esp.employee_name      pattern_employee_name,
			CAST(ts.pattern_begin_work_dt AS DATETIME) pattern_begin_work_dt,
			CAST(ts.pattern_end_of_work_dt AS DATETIME) pattern_end_of_work_dt,
			ts.cut_employee_id,
			esc.employee_name      cut_employee_name,
			CAST(ts.cut_begin_work_dt AS DATETIME) cut_begin_work_dt,
			CAST(ts.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt,
			ts.employee_id,
			es.employee_name,
			CAST(ts.create_dt AS DATETIME) dt,
			ISNULL(ts.pattern_comment + ' / ', '') + ISNULL(ts.cut_comment, '') comment,
			CAST(ts.problem_dt AS DATETIME) problem_dt,
			ISNULL(ts.problem_comment, '') problem_comment,
			ts.problem_employee_id,
			espr.employee_name     problem_employee_name
	FROM	Manufactory.TaskSample ts   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			LEFT JOIN	Settings.EmployeeSetting esp
				ON	ts.pattern_employee_id = esp.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	ts.cut_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	ts.employee_id = es.employee_id   
			LEFT JOIN	Settings.EmployeeSetting espr
				ON	ts.problem_employee_id = espr.employee_id
	WHERE	ts.is_deleted = 0
			AND	EXISTS (
			   		SELECT	1
			   		FROM	#t t
			   		WHERE	ts.task_sample_id = t.task_sample_id
			   	)
	
	SELECT	s.sample_id,
			s.sketch_id,
			s.task_sample_id,
			s.st_id,
			st.st_name,
			ts.ts_name,
			ct.ct_name,
			s.comment,
			CAST(s.sew_launch_dt AS DATETIME) sew_launch_dt,
			s.sew_launch_employee_id,
			es.employee_name sew_launch_employee_name,
			s.pattern_perimeter,
			s.cut_perimeter,
			CAST(ts2.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt
	FROM	#t s   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Manufactory.TaskSample ts2
				ON	ts2.task_sample_id = s.task_sample_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	s.sew_launch_employee_id = es.employee_id
	
	
	
	SELECT	ts.ts_id,
			ts.qp_id,
			qp.qp_name,
			ts.ct_id,
			ct.ct_name,
			ts.office_id,
			ts.employee_id,
			es.employee_name,
			CAST(ts.create_dt AS DATETIME) dt,
			ts.priority_employee_id,
			espri.employee_name     priority_employee_name,
			ts.sew_employee_id,
			essew.employee_name     sew_employee_name,
			CAST(ts.sew_begin_work_dt AS DATETIME) sew_begin_work_dt,
			CAST(ts.sew_end_work_dt AS DATETIME) sew_end_work_dt,
			ts.comment,
			ts.estimated_time,
			CAST(tsr.create_dt AS DATETIME) rework_dt
	FROM	Manufactory.TaskSew ts   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			LEFT JOIN	Manufactory.TaskSewRework tsr
				ON	tsr.ts_id = ts.ts_id
				AND	tsr.close_dt IS NULL   
			LEFT JOIN	Settings.EmployeeSetting espri
				ON	espri.employee_id = ts.priority_employee_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = ts.employee_id   
			LEFT JOIN	Settings.EmployeeSetting essew
				ON	essew.employee_id = ts.sew_employee_id
	WHERE	ts.is_deleted = 0
			AND	EXISTS (
			   		SELECT	1
			   		FROM	#t t   
			   				INNER JOIN	Manufactory.TaskSewSample tss
			   					ON	tss.sample_id = t.sample_id
			   		WHERE	ts.ts_id = tss.ts_id
			   	) 
	
	SELECT	tss.tss_id,
			tss.ts_id,
			tss.sample_id,
			tss.stream_time,
			st.st_name,
			ts.ts_name,
			ct.ct_name,
			CAST(tss.has_problem_dt AS DATETIME) has_problem_dt,
			tss.close_problem_employee_id,
			escp.employee_name     close_problem_employee_name,
			CAST(tss.close_problem_dt AS DATETIME) close_problem_dt,
			tss.close_employee_id,
			esc.employee_name      close_employee_name,
			CAST(tss.close_dt AS DATETIME) close_dt,
			CASE 
			     WHEN tsr.new_ts_id IS NOT NULL THEN 1
			     ELSE 0
			END                    is_rework
	FROM	#t t   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.sample_id = t.sample_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = t.ts_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = t.st_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = t.ct_id   
			LEFT JOIN	Manufactory.TaskSewRework tsr
				ON	tsr.new_ts_id = tss.ts_id   
			LEFT JOIN	Settings.EmployeeSetting escp
				ON	escp.employee_id = tss.close_problem_employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	esc.employee_id = tss.close_employee_id
	
	SELECT	tsr.tsr_id,
			tsr.ts_id,
			CAST(tsr.create_dt AS DATETIME) create_dt,
			tsr.sew_employee_id,
			es.employee_name      sew_employee_name,
			CAST(tsr.close_dt AS DATETIME) close_dt,
			tsr.close_employee_id,
			esc.employee_name     close_employee_name,
			tsr.comment
	FROM	Manufactory.TaskSewRework tsr   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	tsr.sew_employee_id = es.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	esc.employee_id = tsr.close_employee_id
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	#t t   
	     				INNER JOIN	Manufactory.TaskSewSample tss
	     					ON	tss.sample_id = t.sample_id
	     		WHERE	tsr.ts_id = tss.ts_id
	     	) 