CREATE PROCEDURE [Manufactory].[TaskEmployee_ReportByPeriod]
	@start_dt dbo.SECONDSTIME,
	@finish_dt dbo.SECONDSTIME
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.pattern_employee_id     employee_id,
			'Вырезка лекал'            job_type,
			CAST(ts.pattern_end_of_work_dt AS DATETIME) end_dt,
			s.pattern_perimeter        perimeter,
			ct.ct_name,
			0                          stream_time,
			st.st_name,
			sk.sa_local,
			an.art_name,
			b.brand_name,
			tsz.ts_name,
			CAST(0 AS BIT) is_mixed,
			CAST(0 AS BIT) has_rework,
			CAST(0 AS BIT) is_rework
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id
			INNER JOIN Products.Brand b
				ON b.brand_id = sk.brand_id
	WHERE	ts.pattern_end_of_work_dt >= @start_dt
			AND	ts.pattern_end_of_work_dt <= @finish_dt
			AND s.pattern_perimeter != 0
			AND ts.is_stm = 0
			AND ts.is_deleted = 0
	UNION ALL
	SELECT	ts.cut_employee_id,
			'Крой',
			CAST(ts.cut_begin_work_dt AS DATETIME),
			s.cut_perimeter,
			ct.ct_name,
			0,
			st.st_name,
			sk.sa_local,
			an.art_name,
			b.brand_name,
			tsz.ts_name,
			CAST(0 AS BIT) is_mixed,
			CAST(0 AS BIT) has_rework,
			CAST(0 AS BIT) is_rework
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id
			INNER JOIN Products.Brand b
				ON b.brand_id = sk.brand_id
	WHERE	ts.cut_end_of_work_dt >= @start_dt
			AND	ts.cut_end_of_work_dt <= @finish_dt
			AND s.cut_perimeter != 0
			AND ts.is_stm = 0
			AND ts.is_deleted = 0
	UNION ALL	
	SELECT	tsew.sew_employee_id,
			CASE 
				 WHEN oatsr.ts_id IS NOT NULL AND tss.has_problem_dt IS NOT NULL THEN 'Отшив(с проблемой и переделкой)'
				 WHEN oatsr.ts_id IS NOT NULL AND tss.has_problem_dt IS NULL THEN 'Отшив(с переделкой)'
				 WHEN oatsr.ts_id IS NULL AND tss.has_problem_dt IS NOT NULL THEN 'Отшив(с проблемой)'
				 WHEN tsr.tsr_id IS NOT NULL AND tss.has_problem_dt IS NOT NULL THEN 'Переделка(с проблемой)'
				 WHEN tsr.tsr_id IS NOT NULL AND tss.has_problem_dt IS NULL THEN 'Переделка'
			     ELSE 'Отшив'
			END,
			CAST(tss.close_dt AS DATETIME),
			0,
			ct.ct_name,
			tss.stream_time,
			st.st_name,
			sk.sa_local,
			an.art_name,
			b.brand_name,
			tsz.ts_name,
			CAST(ISNULL(tss.is_mixed, 0) AS BIT) is_mixed,
			CAST(CASE 
			     WHEN oatsr.ts_id IS NOT NULL THEN 1
			     ELSE 0
			END AS BIT) has_rework,
			CAST(CASE 
			     WHEN tsr.tsr_id IS NOT NULL THEN 1
			     ELSE 0
			END AS BIT) is_rework
	FROM	Manufactory.[Sample] s   
			INNER JOIN	Products.TechSize tsz
				ON	tsz.ts_id = s.ts_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = s.task_sample_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = s.sketch_id   
			INNER JOIN	Manufactory.SampleType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Manufactory.TaskSewSample tss
				ON	tss.sample_id = s.sample_id   
			INNER JOIN	Manufactory.TaskSew tsew
				ON	tsew.ts_id = tss.ts_id
			INNER JOIN Products.Brand b
				ON b.brand_id = sk.brand_id
			OUTER APPLY (
			      	SELECT	TOP(1) tsr.ts_id
			      	FROM	Manufactory.TaskSewRework tsr
			      	WHERE	tsr.ts_id = tsew.ts_id
			      ) oatsr
			LEFT JOIN Manufactory.TaskSewRework tsr
				ON tsr.new_ts_id = tsew.ts_id
	WHERE	tss.close_dt >= @start_dt
			AND	tss.close_dt <= @finish_dt
			AND ts.is_stm = 0
			AND ts.is_deleted = 0