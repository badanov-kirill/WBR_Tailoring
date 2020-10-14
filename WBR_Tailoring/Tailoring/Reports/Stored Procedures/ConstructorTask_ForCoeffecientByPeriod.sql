CREATE PROCEDURE [Reports].[ConstructorTask_ForCoeffecientByPeriod]
	@start_dt DATETIME2(0),
	@finish_dt DATETIME2(0),
	@only_no_coeff BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция
	
	SELECT	s.sketch_id,
			s.st_id,
			st.st_name,
			s.ss_id,
			s.pic_count,
			s.tech_design,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			s.create_employee_id,
			es2.employee_name create_employee_name,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.employee_id,
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
			ct.ct_name,
			s.pattern_name,
			s.constructor_employee_id,
			es.employee_name            constructor_employee_name,
			oats.x                      ts,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NULL THEN 1
			     ELSE 0
			END                         new_construction,
			CASE 
			     WHEN ss.ss_id = @state_complite_constructor AND s.base_sketch_id IS NOT NULL THEN 1
			     ELSE 0
			END                         new_construction_from_base,
			CAST(ss.dt AS DATETIME)     dt,
			s.constructor_coeffecient,
			CASE WHEN ss.ss_id = @state_complite_constructor_only_file THEN 1 ELSE 0 END only_file,
			s.is_china_sample
	FROM	History.SketchStatus ss   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = ss.sketch_id   
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
			LEFT JOIN	Settings.EmployeeSetting es
				ON	s.constructor_employee_id = es.employee_id 
			LEFT JOIN	Settings.EmployeeSetting es2
				ON	s.create_employee_id = es2.employee_id
			LEFT JOIN Material.ClothType ct
				ON ct.ct_id = s.ct_id   
			OUTER APPLY (
			      	SELECT	ts.ts_name + ';'
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oats(x)
	WHERE	ss.dt >= @start_dt
			AND	ss.dt <= @finish_dt
			AND	ss.ss_id IN (@state_complite_constructor, @state_complite_constructor_only_file)
			AND (@only_no_coeff IS NULL OR (@only_no_coeff = 1 AND s.constructor_coeffecient IS NULL))
			
	ORDER BY
		s.constructor_employee_id,
		s.sketch_id