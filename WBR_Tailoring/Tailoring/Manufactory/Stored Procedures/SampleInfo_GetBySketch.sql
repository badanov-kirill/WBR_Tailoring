CREATE PROCEDURE [Manufactory].[SampleInfo_GetBySketch]
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
			s.cut_perimeter,
			s.is_deleted
	INTO	#t
	FROM	Manufactory.[Sample] s
	WHERE	s.sketch_id = @sketch_id
	
	SELECT	ts.task_sample_id,
			ts.qp_id,
			qp.qp_name,
			ts.pattern_employee_id,
			pes.employee_name     pattern_employee_name,
			CAST(ts.pattern_begin_work_dt AS DATETIME) pattern_begin_work_dt,
			CAST(ts.pattern_end_of_work_dt AS DATETIME) pattern_end_of_work_dt,
			ts.cut_employee_id,
			ces.employee_name     cut_employee_name,
			CAST(ts.cut_begin_work_dt AS DATETIME) cut_begin_work_dt,
			CAST(ts.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt,
			ts.employee_id,
			CAST(ts.create_dt AS DATETIME) dt,
			ISNULL(ts.pattern_comment + ' / ', '') + ISNULL(ts.cut_comment, '') comment,
			CAST(ts.problem_dt AS DATETIME) problem_dt,
			ts.problem_comment,
			ts.problem_employee_id,
			s.sample_id,
			s.sketch_id,
			s.st_id,
			st.st_name,
			tsz.ts_name,
			ct.ct_name,
			s.comment             smaple_comment,
			s.pattern_perimeter,
			s.cut_perimeter,
			s.ts_id,
			s.ct_id,
			s.is_deleted          sample_is_deleted,
			ts.is_deleted         task_is_deleted,
			sop.place_id,
			sp.place_name
	FROM	#t s   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Manufactory.TaskSample ts   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			LEFT JOIN	Settings.EmployeeSetting pes
				ON	ts.pattern_employee_id = pes.employee_id   
			LEFT JOIN	Settings.EmployeeSetting ces
				ON	ts.cut_employee_id = ces.employee_id
				ON	ts.task_sample_id = s.task_sample_id
			LEFT JOIN Warehouse.SampleOnPlace sop
				INNER JOIN Warehouse.StoragePlace sp
					ON sp.place_id = sop.place_id
				ON sop.sample_id = s.sample_id
	
	
