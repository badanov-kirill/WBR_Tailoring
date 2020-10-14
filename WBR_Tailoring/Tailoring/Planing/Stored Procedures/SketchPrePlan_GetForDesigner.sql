CREATE PROCEDURE [Planing].[SketchPrePlan_GetForDesigner]
	@model_year SMALLINT,
	@season_local_id INT = NULL,
	@employee_id INT = NULL,
	@brand_id INT = NULL,
	@ct_id INT = NULL,
	@subject_id INT = NULL,
	@and_del BIT = 0,
	@plan_dt_start DATE = NULL,
	@plan_dt_finish DATE = NULL,
	@spps_id TINYINT = NULL,
	@rmt_id INT = NULL,
	@is_china_sample BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spp.spp_id,
			spps.spps_name,
			spp.season_model_year,
			sl.season_local_name,
			spp.sketch_id,
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
			os.office_name     sew_office_name,
			oa_p.x             office_pattern,
			CAST(spp.plan_dt AS DATETIME) plan_dt,
			spp.plan_qty,
			spp.cv_qty,
			oa_c.x             comment,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			ISNULL(ss.ss_short_name, ss.ss_name) sketch_status,
			spp.season_local_id,
			s.days_for_purchase,
			es.employee_name,
			oa_n.cnt_nm_syte,
			CASE 
			     WHEN spp.plan_dt IS NOT NULL AND s.fist_package_dt IS NOT NULL AND DATEDIFF(DAY, spp.plan_dt, s.fist_package_dt) > -60 THEN 'Новинка'
			     WHEN (spp.plan_dt IS NULL OR s.fist_package_dt IS NULL) AND ISNULL(oa_n.cnt_nm_syte, 0) = 0 THEN 'Новинка'
			     ELSE ''
			END is_new_comment
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Planing.SketchPrePlanStatus spps
				ON	spps.spps_id = spp.spps_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = spp.sketch_id   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = spp.season_local_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spp.sew_office_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	spp.employee_id = es.employee_id   
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
			OUTER APPLY (
			               	SELECT	sppc.comment + ' | '
			               	FROM	Planing.SketchPrePlanComment sppc
			               	WHERE	sppc.spp_id = spp.spp_id
			               	FOR XML	PATH('')
			               ) oa_c(x)
			 OUTER APPLY (
			                SELECT	COUNT(ns.nm_id) cnt_nm_syte
			                FROM	Products.Nomenclature_Statistics ns
			                WHERE	(
			                     		EXISTS(
			                     			SELECT	1
			                     			FROM	Products.ProdArticle pa   
			                     					INNER JOIN	Products.ProdArticleNomenclature pan
			                     						ON	pan.pa_id = pa.pa_id
			                     			WHERE	pan.nm_id = ns.nm_id
			                     					AND	pa.sketch_id = s.sketch_id
			                     		)
			                     		OR EXISTS (
			                     		   	SELECT	1
			                     		   	FROM	Products.ERP_IMT_Sketch eis   
			                     		   			INNER JOIN	Products.ERP_NM_Sketch ens
			                     		   				ON	ens.imt_id = eis.imt_id
			                     		   	WHERE	eis.sketch_id = s.sketch_id
			                     		   			AND	ns.nm_id = ens.nm_id
			                     		   )
			                     	)
			                		AND	ns.income_qty > 0
			                ) oa_n                               
	WHERE	spp.season_model_year = @model_year
			AND	(@season_local_id IS NULL OR spp.season_local_id = @season_local_id)
			AND	(@employee_id IS NULL OR spp.create_employee_id = @employee_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@and_del = 1 OR spp.spps_id != 3)
			AND	(@plan_dt_start IS NULL OR spp.plan_dt >= @plan_dt_start)
			AND	(@plan_dt_finish IS NULL OR spp.plan_dt <= @plan_dt_finish)
			AND	(@spps_id IS NULL OR spp.spps_id = @spps_id)
			AND	(@is_china_sample IS NULL OR s.is_china_sample = @is_china_sample)
			AND	(
			   		@rmt_id IS NULL
			   		OR EXISTS (
			   		   	SELECT	TOP(1) 1
			   		   	FROM	Products.SketchCompleting sc   
			   		   			LEFT JOIN	Products.SketchCompletingRawMaterial scrm
			   		   				ON	scrm.sc_id = sc.sc_id
			   		   	WHERE	sc.sketch_id = s.sketch_id
			   		   			AND sc.is_deleted = 0
			   		   			AND	(scrm.rmt_id = @rmt_id OR sc.base_rmt_id = @rmt_id)
			   		   )			   		
			)