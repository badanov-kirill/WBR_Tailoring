CREATE PROCEDURE [Manufactory].[SkecthPlan_GetForSetTechnolog]
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
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			CAST(oa.create_dt AS DATETIME) job_create_dt,
			oa.qp_id,
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
			OUTER APPLY (
			      	SELECT	TOP(1) stj.create_dt,
			      			stj.qp_id
			      	FROM	Products.SketchTechnologyJob stj
			      	WHERE	stj.begin_employee_id IS NULL
			      			AND	stj.end_dt IS NULL
			      			AND	s.sketch_id = stj.sketch_id
			      	ORDER BY
			      		stj.stj_id ASC
			      )               oa
	WHERE	(s.technology_employee_id IS NULL OR s.technology_dt IS NULL)
			AND	EXISTS (
			   		SELECT	1
			   		FROM	Planing.SketchPlan sp
			   		WHERE	sp.sketch_id = s.sketch_id
			   				AND	sp.ps_id IN (2, 4, 5, 6, 7, 8, 10)
			   				AND	sp.spp_id IS NOT NULL
			   	)
	ORDER BY
		s.plan_site_dt ASC