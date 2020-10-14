CREATE PROCEDURE [Manufactory].[TaskSample_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sample_id,
			s.task_sample_id,
			s.st_id,
			st.st_name,
			s.pattern_perimeter,
			s.cut_perimeter,
			s.ts_id,
			ts.ts_name,
			s.ct_id,
			ct.ct_name,
			s.employee_id,
			CAST(s.dt AS DATETIME) dt,
			s.comment
	INTO	#t
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id
	WHERE	s.sketch_id = @sketch_id
			AND	s.is_deleted = 0	
	
	SELECT	ts.task_sample_id,
			ts.qp_id,
			qp.qp_name,
			ts.ct_id,
			ct.ct_name,
			ts.office_id,
			ts.pattern_employee_id,
			CAST(ts.pattern_begin_work_dt AS DATETIME) pattern_begin_work_dt,
			CAST(ts.pattern_end_of_work_dt AS DATETIME) pattern_end_of_work_dt,
			ts.cut_employee_id,
			CAST(ts.cut_begin_work_dt AS DATETIME) cut_begin_work_dt,
			CAST(ts.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt,
			ts.employee_id,
			CAST(ts.create_dt AS DATETIME) dt,
			CAST(ts.problem_dt AS DATETIME) problem_dt, 
			ts.problem_comment
	FROM	Manufactory.TaskSample ts   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id
	WHERE	ts.is_deleted = 0
			AND	EXISTS (
			   		SELECT	1
			   		FROM	#t t
			   		WHERE	ts.task_sample_id = t.task_sample_id
			   	)
	
	
	SELECT	t.sample_id,
			t.task_sample_id,
			t.st_id,
			t.st_name,
			t.pattern_perimeter,
			t.cut_perimeter,
			t.ts_id,
			t.ts_name,
			t.ct_id,
			t.ct_name,
			t.employee_id,
			t.dt,
			t.comment
	FROM	#t t
	