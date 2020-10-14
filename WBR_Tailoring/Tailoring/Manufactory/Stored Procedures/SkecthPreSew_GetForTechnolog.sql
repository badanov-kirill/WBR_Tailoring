CREATE PROCEDURE [Manufactory].[SkecthPreSew_GetForTechnolog]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			st.st_name,
			s.pic_count,
			s.tech_design,
			k.kind_name,
			sj.subject_name,
			an.art_name,
			b.brand_name,
			sn.season_name,
			s.sa,
			s.imt_name,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			sl.season_local_name,
			s.season_model_year,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			esc.employee_name         constructor_employee_name,
			est.employee_name         technology_employee_name,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			CAST(stj.create_dt AS DATETIME) job_create_dt,
			stj.qp_id,
			ct.ct_name
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
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
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	s.technology_employee_id = est.employee_id   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.SketchTechnologyJob stj
				ON	stj.sketch_id = s.sketch_id
				AND	stj.end_dt IS     NULL
	WHERE	stj.stjt_id = 2
	ORDER BY
		stj.qp_id,
		s.qp_id,
		stj.stj_id