CREATE PROCEDURE [Reports].[SketchTechnologyJob_Get]
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	SELECT	b.brand_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			an.art_name,
			s.sa,
			ct.ct_name,
			qp.qp_name,
			sl.season_local_name,
			s.season_model_year,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			CAST(stj.create_dt AS DATETIME) job_create_dt
	FROM	Products.SketchTechnologyJob stj   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = stj.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.QueuePriority qp
				ON	qp.qp_id = stj.qp_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = s.season_id   
			LEFT JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = s.season_local_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	s.technology_employee_id = est.employee_id
	WHERE	stj.begin_employee_id IS NULL
			AND	stj.end_dt IS NULL
			AND	(@employee_id IS NULL OR s.technology_employee_id = @employee_id)
	ORDER BY
		stj.qp_id              ASC,
		s.qp_id                ASC,
		stj.stj_id             ASC