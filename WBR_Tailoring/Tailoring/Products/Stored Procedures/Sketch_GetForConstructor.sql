CREATE PROCEDURE [Products].[Sketch_GetForConstructor]
	@constructor_employee_id INT = NULL,
	@brand_id INT = NULL,
	@subject_id INT = NULL,
	@art_name VARCHAR(50) = NULL,
	@is_china_sample BIT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @state_appointed_constructor TINYINT = 8 --Назначен конструктору
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором	
	DECLARE @state_need_tect_desig_correction_from_constructor TINYINT = 11 --Тех. эскиз отправлен на доработку конструктором	
	DECLARE @state_tech_design_take_job_amend_from_constructor TINYINT = 12 --Тех. эскиз взят на исправление от конструктора	
	DECLARE @state_tech_desig_confirm_from_constructor TINYINT = 13 --Тех. эскиз доработан по требованию конструктора
	DECLARE @state_appointed_constructor_rework TINYINT = 14 --Назначен на доработку конструктору
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @state_appointed_layout TINYINT = 20 --Назначен раскладсику
	DECLARE @state_appointed_layout_end TINYINT = 21 --Закончено прикрепление раскладок 
	
	SELECT	s.sketch_id,
			s.st_id,
			st.st_name,
			s.ss_id,
			ss.ss_name,
			s.pic_count,
			s.tech_design,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			s.create_employee_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.employee_id,
			CAST(s.dt AS DATETIME)     dt,
			s.status_comment,
			s.qp_id,
			qp.qp_name,
			an.art_name,
			s.brand_id,
			b.brand_name,
			s.season_id,
			sn.season_name,
			s.model_year,
			s.sa_local,
			s.sa,
			s.pattern_name,
			s.constructor_employee_id,
			oats.x                     ts,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			oap.problem_dt,
			s.season_model_year,
			sl.season_local_name,
			CASE 
			     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN  CAST(DATEADD(DAY, -(s.days_for_purchase + 60 ), s.plan_site_dt) AS DATETIME)
			     WHEN ISNULL(s.days_for_purchase, 0) = 0 AND s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			     ELSE CAST(DATEADD(DAY, -180, s.plan_site_dt) AS DATETIME)
			END                        plan_dt,
			CAST(s.layout_dt AS DATETIME) layout_dt,
			s.ct_id,
			ct.ct_name,
			s.is_china_sample,
			CAST(oach.create_dt AS DATETIME) china_task_create_dt,
			CAST(oach.close_dt AS DATETIME) china_task_close_dt,
			s.allow_purchase_no_close
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = s.qp_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = s.season_local_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			OUTER APPLY (
			      	SELECT	ts.ts_name + ';'
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oats(x)OUTER APPLY (
			                     	SELECT	TOP(1) CAST(ts.problem_dt AS DATETIME) problem_dt
			                     	FROM	Manufactory.[Sample] sam   
			                     			INNER JOIN	Manufactory.TaskSample ts
			                     				ON	ts.task_sample_id = sam.task_sample_id
			                     	WHERE	sam.sketch_id = s.sketch_id
			                     			AND	ts.problem_dt IS NOT NULL
			                     ) oap
	OUTER APPLY (
	      	SELECT	TOP(1) tcs.create_dt,
	      			tcs.close_dt
	      	FROM	Manufactory.TaskChinaSample tcs
	      	WHERE	tcs.sketch_id = s.sketch_id
	      	ORDER BY
	      		tcs.tcs_id DESC
	      )                            oach
	WHERE	s.ss_id IN (@state_appointed_constructor, @state_constructor_take_job_add, @state_need_tect_desig_correction_from_constructor, 
	     	           @state_tech_desig_confirm_from_constructor, @state_tech_design_take_job_amend_from_constructor, @state_appointed_constructor_rework, 
	     	           @state_constructor_take_job_add_rework, @state_appointed_layout, @state_appointed_layout_end)
			AND	s.is_deleted = 0
			AND	(@constructor_employee_id IS NULL OR s.constructor_employee_id = @constructor_employee_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@is_china_sample IS NULL OR (s.is_china_sample = @is_china_sample))
	ORDER BY
		CASE 
			     WHEN ISNULL(s.days_for_purchase, 0) != 0 THEN  CAST(DATEADD(DAY, -(s.days_for_purchase + 60 ), s.plan_site_dt) AS DATETIME)
			     WHEN ISNULL(s.days_for_purchase, 0) = 0 AND s.plan_site_dt < DATEFROMPARTS(2020, 06, 1) THEN CAST(DATEADD(DAY, -75, s.plan_site_dt) AS DATETIME)
			     ELSE CAST(DATEADD(DAY, -180, s.plan_site_dt) AS DATETIME)
			END,
		sketch_id
			