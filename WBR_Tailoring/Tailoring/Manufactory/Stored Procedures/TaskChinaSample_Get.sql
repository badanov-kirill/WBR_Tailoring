CREATE PROCEDURE [Manufactory].[TaskChinaSample_Get]
	@brand_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@subject_id INT = NULL,
	@sa VARCHAR(36) = NULL,
	@season_id INT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	tcs.tcs_id,
			tcs.comment,
			s.sketch_id,
			s.pic_count,
			s.tech_design,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			cast(tcs.create_dt AS DATETIME) create_dt,
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
			s.descr
	FROM	Manufactory.TaskChinaSample tcs   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = tcs.sketch_id   
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
	WHERE	tcs.close_dt IS NULL
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@sa IS NULL OR s.sa LIKE '%' + @sa + '%')
			AND	(@season_id IS NULL OR s.season_id = @season_id)
	ORDER BY
		s.sketch_id               DESC