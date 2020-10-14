CREATE PROCEDURE [Manufactory].[TaskSew_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_id,
			s.sample_id,
			ct.ct_name,
			s.sketch_id,
			st.st_name,
			tsz.ts_name,
			ISNULL(sk.pattern_name, sk.sa_local) sa,
			an.art_name,
			sj.subject_name_sf subject_name,
			ts.employee_id technolog_employee_id,
			s.comment,
			ts.comment job_comment,
			s.employee_id,
			est.employee_name     technology_employee_name,
			esc.employee_name     constructor_employee_name,
			b.brand_name
	FROM	Manufactory.TaskSew ts   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.ts_id = ts.ts_id   
			INNER JOIN	Manufactory.[Sample] s
				ON	s.sample_id = tss.sample_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			LEFT JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id 
			INNER JOIN Products.Brand b
				ON b.brand_id = sk.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id
			LEFT JOIN	Settings.EmployeeSetting est
				ON	sk.technology_employee_id = est.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	sk.constructor_employee_id = esc.employee_id
	WHERE	ts.sew_employee_id = @employee_id
			AND	ts.sew_end_work_dt IS NULL
			AND	ts.is_deleted = 0
			AND	s.is_deleted = 0