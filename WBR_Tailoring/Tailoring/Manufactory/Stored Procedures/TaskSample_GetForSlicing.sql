CREATE PROCEDURE [Manufactory].[TaskSample_GetForSlicing]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.task_sample_id,
			s.sketch_id,
			s.sa_local,
			s.tech_design,
			s.pic_count,
			an.art_name,
			sj.subject_name,
			esd.employee_name     designer_employee_name,
			esc.employee_name     constructor_employee_name,
			qp.qp_name,
			oa.x                  sample_info,
			ct.ct_name,
			CAST(ts.create_dt AS DATETIME) create_dt,
			ts.qp_id,
			ts.problem_comment
	FROM	Manufactory.TaskSample ts   
			OUTER APPLY (
			      	SELECT	st.st_name + ' ' + tecs.ts_name + '; '
			      	FROM	Manufactory.[Sample] s   
			      			INNER JOIN	Manufactory.SampleType st
			      				ON	st.st_id = s.st_id   
			      			INNER JOIN	Products.TechSize tecs
			      				ON	tecs.ts_id = s.ts_id
			      	WHERE	s.task_sample_id = ts.task_sample_id
			      			AND	s.is_deleted = 0
			      	FOR XML	PATH('')
			      ) oa(x)CROSS APPLY (
			                   	SELECT	TOP(1) s.sketch_id
			                   	FROM	Manufactory.[Sample] s
			                   	WHERE	s.task_sample_id = ts.task_sample_id
			                   			AND	s.is_deleted = 0
			                   ) oa_s
	INNER JOIN	Products.Sketch s
				ON	s.sketch_id = oa_s.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = ts.qp_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			LEFT JOIN	Settings.EmployeeSetting esd
				ON	s.create_employee_id = esd.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id
	WHERE	ts.slicing_dt IS NULL
			AND	ts.is_deleted = 0
	ORDER BY
		ts.qp_id ASC,
		ts.task_sample_id ASC