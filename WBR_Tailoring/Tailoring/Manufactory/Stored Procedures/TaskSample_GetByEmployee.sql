CREATE PROCEDURE [Manufactory].[TaskSample_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.task_sample_id,
			s.sample_id,
			ct.ct_name,
			s.sketch_id,
			st.st_name,
			tsz.ts_name,
			ISNULL(sk.pattern_name, sk.sa_local) sa,
			an.art_name,
			sj.subject_name,
			ts.employee_id,
			s.comment,
			CASE 
			     WHEN ts.pattern_end_of_work_dt IS NULL THEN 'Лекала'
			     ELSE 'Крой'
			END job_type,
			s.pattern_perimeter, 
			s.cut_perimeter
	FROM	Manufactory.TaskSample ts     
			INNER JOIN	Manufactory.[Sample] s
				ON	s.task_sample_id = ts.task_sample_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			LEFT JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = sk.subject_id
			INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = s.ct_id
	WHERE	((ts.pattern_employee_id = @employee_id AND ts.pattern_end_of_work_dt IS NULL) OR (ts.cut_employee_id = @employee_id AND ts.cut_end_of_work_dt IS NULL))
			AND	ts.is_deleted = 0
			AND	s.is_deleted = 0