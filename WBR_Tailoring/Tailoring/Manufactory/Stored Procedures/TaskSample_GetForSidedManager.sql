CREATE PROCEDURE [Manufactory].[TaskSample_GetForSidedManager]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	es_cons.employee_name     constructor_name,
			an.art_name,
			sj.subject_name_sf subject_name,
			qp.qp_name,
			ct.ct_name,
			st.st_name,
			tsz.ts_name,
			CAST(ts.create_dt AS DATETIME) create_dt,
			s.sketch_id,
			b.brand_name,
			ts.task_sample_id,
			sm.sample_id,
			ts.is_stm,
			ts.problem_comment        comment,
			ts.pattern_comment,
			ts.cut_comment,
			s.sa_local
	FROM	Manufactory.TaskSample ts   
			LEFT JOIN	Settings.EmployeeSetting es_cons
				ON	es_cons.employee_id = ts.employee_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Manufactory.[Sample] sm
				ON	sm.task_sample_id = ts.task_sample_id   
			INNER JOIN	Products.Sketch s
				ON	sm.sketch_id = s.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = sm.st_id   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = sm.ts_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id
	WHERE	sm.is_deleted = 0
			AND	ts.is_deleted = 0
			AND	ts.cut_end_of_work_dt IS NULL
	ORDER BY
		ts.is_stm,
		ts.task_sample_id          ASC