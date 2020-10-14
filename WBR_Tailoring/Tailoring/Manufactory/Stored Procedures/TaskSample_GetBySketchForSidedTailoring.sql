CREATE PROCEDURE [Manufactory].[TaskSample_GetBySketchForSidedTailoring]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.task_sample_id,
			ts.cut_employee_id,
			CAST(ts.cut_begin_work_dt AS DATETIME) cut_begin_work_dt,
			CAST(ts.cut_end_of_work_dt AS DATETIME) cut_end_of_work_dt,
			oa.x                     sample_info,
			oas.sew_employee_id
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
			      ) oa(x)
			OUTER APPLY (
			                   	SELECT	TOP(1) tsew.sew_employee_id
			                   	FROM	Manufactory.TaskSewSample tss   
			                   			INNER JOIN	Manufactory.TaskSew tsew
			                   				ON	tsew.ts_id = tss.ts_id   
			                   			INNER JOIN	Manufactory.[Sample] s
			                   				ON	s.sample_id = tss.sample_id
			                   	WHERE	s.task_sample_id = ts.task_sample_id
			                   			AND	tsew.sew_employee_id IS NOT NULL
			                   			AND	tsew.sew_end_work_dt IS NULL
			                   )     oas
	WHERE	ts.is_stm = 1
			AND	(ts.cut_begin_work_dt IS NULL AND ts.cut_end_of_work_dt IS NULL)
			AND	EXISTS (
			   		SELECT	1
			   		FROM	Manufactory.[Sample] s
			   		WHERE	s.task_sample_id = ts.task_sample_id
			   				AND	s.sketch_id = @sketch_id
			   	)
	
	SELECT	s.sketch_id,
			an.art_name,
			s.sa,
			b.brand_name,
			sj.subject_name
	FROM	Products.Sketch s   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	s.sketch_id = @sketch_id