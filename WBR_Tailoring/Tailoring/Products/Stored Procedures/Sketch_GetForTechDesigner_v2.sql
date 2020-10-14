CREATE PROCEDURE [Products].[Sketch_GetForTechDesigner_v2]
	@art_name VARCHAR(50) = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @state_create TINYINT = 1 --Создан
	DECLARE @state_need_tect_desig_correction TINYINT = 4 --Технический эскиз отклонен дизайнером
	DECLARE @state_tech_desig_take_job_add TINYINT = 6 --Взято в работу техническис дизайнером
	DECLARE @state_tech_design_take_job_amend TINYINT = 7 --Взято на исправление техническим дизайнером
	DECLARE @state_need_tect_desig_correction_from_constructor TINYINT = 11 --Тех. эскиз отправлен на доработку конструктором	
	DECLARE @state_tech_design_take_job_amend_from_constructor TINYINT = 12 --Тех. эскиз взят на исправление от конструктора
	DECLARE @state_need_tect_desig_correction_from_desig TINYINT = 17 --	Тех. эскиз c гот. констр. отпр. на доработку диз-м
	DECLARE @state_tech_design_take_job_amend_from_desig TINYINT = 18 --	Тех. эскиз c гот. констр. взят на дораб-у от диз-а
	
	
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
			s.constructor_employee_id
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
	WHERE	(
	     		(
	     			@art_name IS NULL
	     			AND s.ss_id 
	     			    IN (@state_create, @state_need_tect_desig_correction, @state_tech_desig_take_job_add, @state_tech_design_take_job_amend, @state_need_tect_desig_correction_from_constructor, 
	     			       @state_tech_design_take_job_amend_from_constructor, @state_need_tect_desig_correction_from_desig, @state_tech_design_take_job_amend_from_desig)
	     		)
	     		OR (@art_name IS NOT NULL AND an.art_name LIKE @art_name + '%')
	     	)
			AND	s.is_deleted = 0
	ORDER BY
		s.qp_id                     ASC,
		s.sketch_id                 ASC
			