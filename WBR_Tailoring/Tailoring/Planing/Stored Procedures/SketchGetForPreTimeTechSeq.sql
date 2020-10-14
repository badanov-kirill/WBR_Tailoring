CREATE PROCEDURE [Planing].[SketchGetForPreTimeTechSeq]
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@brand_id INT = NULL,
	@ct_id INT = NULL,
	@subject_id INT = NULL,
	@plan_dt_start DATE = NULL,
	@plan_dt_finish DATE = NULL,
	@art_name VARCHAR(100) = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.season_model_year,
			sl.season_local_name,
			s.sketch_id,
			s.pic_count,
			s.tech_design,
			b.brand_name,
			sj.subject_name,
			ct.ct_name,
			an.art_name,
			s.sa,
			CAST(s.pattern_print_dt AS DATETIME) pattern_print_dt,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			oa_p.x office_pattern,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			ISNULL(ss.ss_short_name, ss.ss_name) sketch_status,
			s.pre_time_tech_seq,
			s.loops, 
			s.buttons
	FROM	Products.Sketch s   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = s.season_local_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id    
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	WHERE	(s.pre_time_tech_seq IS NULL OR @art_name IS NOT NULL)
			AND ISNULL(s.is_china_sample, 0) = 0
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(
			   		EXISTS (
			   			SELECT	TOP(1) 1
			   			FROM	Planing.SketchPrePlan spp
			   			WHERE	spp.sketch_id = s.sketch_id
			   					AND	(@plan_dt_start IS NULL OR spp.plan_dt >= @plan_dt_start)
			   					AND	(@plan_dt_finish IS NULL OR spp.plan_dt <= @plan_dt_finish)
			   					AND	(@model_year IS NULL OR spp.season_model_year = @model_year)
			   					AND	(@season_local_id IS NULL OR spp.season_local_id = @season_local_id)
			   					AND	spp.spps_id IN (1, 2)
			   		)
			)
	ORDER BY s.sketch_id