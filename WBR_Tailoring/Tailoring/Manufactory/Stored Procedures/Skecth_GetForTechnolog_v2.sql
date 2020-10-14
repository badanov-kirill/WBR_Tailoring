CREATE PROCEDURE [Manufactory].[Skecth_GetForTechnolog_v2]
	@office_id INT,
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sk.sketch_id,
			ISNULL(sk.pattern_name, sk.sa_local) sa_local,
			an.art_name,
			sk.create_employee_id,
			sk.constructor_employee_id,
			sj.subject_name,
			ct.ct_name,
			0                     sew,
			qp.qp_name,
			sk.pic_count,
			0                     has_problem,
			s.st_id,
			st.st_name,
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			esd.employee_name     designer_employee_name
	FROM	Manufactory.TaskSample ts   
			INNER JOIN	Manufactory.[Sample] s
				ON	s.task_sample_id = ts.task_sample_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	sk.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	sk.technology_employee_id = est.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esd
				ON	sk.create_employee_id = esd.employee_id
	WHERE	ts.cut_end_of_work_dt IS NOT NULL
			AND	ts.is_deleted = 0
			AND	s.sew_launch_dt IS NULL
			AND	s.is_deleted = 0
			AND	ts.office_id = @office_id
			AND	ts.is_stm = 0
			AND	(@employee_id IS NULL OR sk.technology_employee_id = @employee_id)
	UNION
	SELECT	sk.sketch_id,
			ISNULL(sk.pattern_name, sk.sa_local) sa_local,
			an.art_name,
			sk.create_employee_id,
			sk.constructor_employee_id,
			sj.subject_name,
			ct.ct_name,
			1                     sew,
			qp.qp_name,
			sk.pic_count,
			CASE 
			     WHEN tss.has_problem_dt IS NOT NULL THEN 1
			     WHEN tsr.tsr_id IS NOT NULL THEN 1
			     ELSE 0
			END                   has_problem,
			s.st_id,
			st.st_name,
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			esd.employee_name     designer_employee_name
	FROM	Manufactory.TaskSew ts   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.ts_id = ts.ts_id   
			INNER JOIN	Manufactory.[Sample] s
				ON	s.sample_id = tss.sample_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			LEFT JOIN	Manufactory.TaskSewRework tsr
				ON	tsr.ts_id = ts.ts_id
				AND	tsr.close_dt IS NULL   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	sk.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	sk.technology_employee_id = est.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esd
				ON	sk.create_employee_id = esd.employee_id
	WHERE	ts.is_deleted = 0
			AND	((tss.has_problem_dt IS NOT NULL AND tss.close_problem_dt IS NULL) OR (ts.sew_end_work_dt IS NOT NULL AND tss.close_dt IS NULL) OR tsr.tsr_id IS NOT NULL)
			AND	ts.office_id = @office_id
			AND	(@employee_id IS NULL OR sk.technology_employee_id = @employee_id)
