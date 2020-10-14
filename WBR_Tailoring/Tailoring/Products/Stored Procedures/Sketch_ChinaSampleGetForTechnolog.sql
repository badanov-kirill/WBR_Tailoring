CREATE PROCEDURE [Products].[Sketch_ChinaSampleGetForTechnolog]
	@art_name VARCHAR(100) = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	DECLARE @state_complite_constructor TINYINT = 10 --Закончено конструирование
	DECLARE @state_complite_constructor_only_file TINYINT = 22 --Закончено конструирование только конструкция
	
	SELECT	s.sketch_id,
			s.pic_count,
			s.tech_design,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			s.employee_id,
			s.dt,
			an.art_name,
			s.brand_id,
			b.brand_name,
			s.season_id,
			sn.season_name,
			s.model_year,
			s.sa_local,
			s.sa,
			s.pattern_name,
			s.imt_name,
			s.constructor_employee_id,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			sl.season_local_name,
			s.season_model_year,
			CAST(s.in_constructor_dt AS DATETIME) in_constructor_dt,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			oats.x                ts,
			s.status_comment,
			s.descr,
			oa.x             ao
	FROM	Products.Sketch s   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = s.season_local_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	s.technology_employee_id = est.employee_id   
			OUTER APPLY (
			      	SELECT	ts.ts_name + ';'
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oats(x)
			OUTER APPLY (
			        SELECT	sao.ao_id '@id',
			        		sao.ao_value '@val',
			        		sao.si_id '@si'
			        FROM	Products.SketchAddedOption sao   
			        		INNER JOIN	Products.AddedOption ao
			        			ON	ao.ao_id = sao.ao_id
			        		INNER JOIN Products.CareThingAddedOption ctao
			        			ON ctao.ao_id = ao.ao_id
			        WHERE	sao.sketch_id = s.sketch_id
			        		AND	ao.isdeleted = 0
			        FOR XML	PATH('ao'), ROOT('aos')
			   ) oa(x)
	WHERE	s.is_china_sample = 1
			AND s.ss_id IN (@state_complite_constructor, @state_complite_constructor_only_file)
			AND	((s.technology_dt IS NULL AND @art_name IS NULL) OR an.art_name LIKE @art_name + '%') 
	ORDER BY
		s.sketch_id               DESC