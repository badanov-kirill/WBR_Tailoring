CREATE PROCEDURE [Manufactory].[TaskQueue_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @st_priority TINYINT = 3
	
	SELECT	ts.employee_id     ts_employee_id,
			an.art_name,
			sj.subject_name_sf,
			qp.qp_name,
			ct.ct_name,
			st.st_name,
			tsz.ts_name,
			CASE 
			     WHEN oa.tp IS NOT NULL THEN 1
			     ELSE 0
			END                is_rework,
			CASE 
			     WHEN (ts.pattern_begin_work_dt IS NULL OR ts.cut_begin_work_dt IS NULL) AND ts.slicing_dt IS NULL THEN 'Склад'	
			     WHEN ts.problem_dt IS NOT NULL THEN 'Отложено'
			     WHEN tsew.sew_begin_work_dt IS NOT NULL AND tsew.sew_end_work_dt IS NULL THEN 'Отшив'
			     WHEN tss.has_problem_dt IS NOT NULL AND tss.close_problem_dt IS NULL THEN 'Проблема'
			     WHEN sm.sew_launch_dt IS NOT NULL THEN 'Очередь на отшив'
			     WHEN ts.cut_end_of_work_dt IS NOT NULL AND sm.sew_launch_dt IS NULL THEN 'В очереди у технолога'
			     WHEN ts.cut_begin_work_dt IS NOT NULL AND ts.cut_end_of_work_dt IS NULL THEN 'Крой'
			     WHEN ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_begin_work_dt IS NULL THEN 'Очередь на крой'
			     WHEN ts.pattern_end_of_work_dt IS NULL AND ts.pattern_begin_work_dt IS NOT NULL THEN 'Вырезка лекал'
			     WHEN ts.pattern_begin_work_dt IS NULL AND ts.slicing_dt IS NOT NULL THEN 'Очередь'
			     WHEN (ts.pattern_begin_work_dt IS NULL OR ts.cut_begin_work_dt IS NULL) AND ts.slicing_dt IS NULL THEN 'Склад'			     
			END                operation_name,
			CASE 
			     WHEN ts.problem_dt IS NOT NULL THEN ts.problem_employee_id
			     WHEN tsew.sew_begin_work_dt IS NOT NULL AND tsew.sew_end_work_dt IS NULL THEN tsew.sew_employee_id
			     WHEN tss.has_problem_dt IS NOT NULL AND tss.close_problem_dt IS NULL THEN tsew.sew_employee_id
			     WHEN sm.sew_launch_dt IS NOT NULL THEN tsew.employee_id
			     WHEN ts.cut_end_of_work_dt IS NOT NULL AND sm.sew_launch_dt IS NULL THEN ts.cut_employee_id
			     WHEN ts.cut_begin_work_dt IS NOT NULL AND ts.cut_end_of_work_dt IS NULL THEN ts.cut_employee_id
			     WHEN ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_begin_work_dt IS NULL THEN ts.pattern_employee_id
			     WHEN ts.pattern_end_of_work_dt IS NULL AND ts.pattern_begin_work_dt IS NOT NULL THEN ts.pattern_employee_id
			     WHEN ts.pattern_begin_work_dt IS NULL THEN ts.employee_id			     
			END                operation_employee_id,
			CAST(
				CASE 
				     WHEN ts.problem_dt IS NOT NULL THEN ts.problem_dt
				     WHEN tsew.sew_begin_work_dt IS NOT NULL
				AND tsew.sew_end_work_dt IS NULL THEN tsew.sew_begin_work_dt
				    WHEN tss.has_problem_dt IS NOT NULL
				AND tss.close_problem_dt IS NULL THEN tss.has_problem_dt
				    WHEN sm.sew_launch_dt IS NOT NULL THEN sm.sew_launch_dt
				    WHEN ts.cut_end_of_work_dt IS NOT NULL
				AND sm.sew_launch_dt IS NULL THEN ts.cut_end_of_work_dt
				    WHEN ts.cut_begin_work_dt IS NOT NULL
				AND ts.cut_end_of_work_dt IS NULL THEN ts.cut_begin_work_dt
				    WHEN ts.pattern_end_of_work_dt IS NOT NULL
				AND ts.cut_begin_work_dt IS NULL THEN ts.pattern_end_of_work_dt
				    WHEN ts.pattern_end_of_work_dt IS NULL
				AND ts.pattern_begin_work_dt IS NOT NULL THEN ts.pattern_begin_work_dt
				    WHEN ts.pattern_begin_work_dt IS NULL THEN ts.create_dt				    
				    END AS DATETIME
			)                  operation_dt,
			tsew.priority_employee_id,
			esp.employee_name priority_employee_name,
			CAST(ts.create_dt AS DATETIME) create_dt,
			CASE 
			     WHEN tsew.priority_employee_id IS NULL THEN 0
			     ELSE 1
			END                is_priority_employee,
			qp2.qp_name         sew_qp_name,
			s.sketch_id,
			b.brand_name,
			CAST(ts.slicing_dt AS DATETIME) slicing_dt,
			CASE 
			     WHEN s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			     ELSE CAST(DATEADD(DAY, -120, s.plan_site_dt) AS DATETIME)
			END plan_dt,
			ts.problem_comment,
			esc.employee_name constructor_employee_name,
			s.season_model_year,
			sl.season_local_name,
			ts.task_sample_id,
			tsew.ts_id task_sew_id,
			ts.proirity_level,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt
	FROM	Manufactory.TaskSample ts
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
			LEFT JOIN	Manufactory.TaskSewSample tss   
			INNER JOIN	Manufactory.TaskSew tsew
				ON	(tsew.ts_id = tss.ts_id
				AND	tsew.is_deleted = 0)
				ON	tss.sample_id = sm.sample_id
			INNER JOIN Products.Brand b
				ON b.brand_id = s.brand_id
			LEFT JOIN	Products.QueuePriority qp2
				ON	tsew.qp_id = qp2.qp_id
			LEFT JOIN Settings.EmployeeSetting esp
			   ON tsew.priority_employee_id = esp.employee_id
			LEFT JOIN Settings.EmployeeSetting esc
			   ON s.constructor_employee_id = esc.employee_id
			LEFT JOIN Products.SeasonLocal sl
				ON sl.season_local_id = s.season_local_id
			OUTER APPLY (
			      	SELECT	TOP(1) 1 tp
			      	FROM	Manufactory.[Sample] sam
			      	WHERE	sam.task_sample_id = ts.task_sample_id
			      			AND	sam.st_id = @st_priority
			      ) oa
	
	WHERE	sm.is_deleted = 0
			AND	ts.is_deleted = 0
			AND (ts.is_stm = 0 OR ts.is_stm = 1 AND ts.cut_end_of_work_dt IS NULL)
			AND	(
			   		ts.pattern_end_of_work_dt IS NULL
			   		OR ts.cut_end_of_work_dt IS NULL
			   		OR sm.sew_launch_dt IS NULL
			   		OR (tss.has_problem_dt IS NOT NULL AND tss.close_problem_dt IS NULL)
			   		OR tsew.sew_end_work_dt IS NULL
			   	)
	ORDER BY
		CASE 
		     WHEN (ts.pattern_begin_work_dt IS NULL OR ts.cut_begin_work_dt IS NULL) AND ts.slicing_dt IS NULL THEN 100
		     WHEN tss.has_problem_dt IS NOT NULL AND tss.close_problem_dt IS NULL THEN 0		     
		     WHEN tsew.sew_begin_work_dt IS NOT NULL THEN 10
		     WHEN sm.sew_launch_dt IS NOT NULL THEN 20
		     WHEN ts.cut_end_of_work_dt IS NOT NULL AND sm.sew_launch_dt IS NULL THEN 30
		     WHEN ts.cut_begin_work_dt IS NOT NULL AND ts.cut_end_of_work_dt IS NULL THEN 40
		     WHEN ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_employee_id IS NULL THEN 50
		     WHEN ts.pattern_end_of_work_dt IS NULL AND ts.pattern_begin_work_dt IS NOT NULL THEN 60		     
		     ELSE 90
		END                 ASC,
		ts.proirity_level DESC,
		CASE 
		     WHEN oa.tp IS NOT NULL THEN 0
		     ELSE 1
		END                 ASC,
		ts.qp_id            ASC,
		ts.task_sample_id  ASC
		        			