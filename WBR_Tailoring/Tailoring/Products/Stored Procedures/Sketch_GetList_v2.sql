CREATE PROCEDURE [Products].[Sketch_GetList_v2]
	@ss_id INT = NULL,
	@is_deleted BIT = 0,
	@creator_employee_id INT = NULL,
	@brand_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@subject_id INT = NULL,
	@nm_id INT = NULL,
	@sa VARCHAR(36) = NULL,
	@constructor_employee_id INT = NULL,
	@ct_id INT = NULL,
	@rmt_id INT = NULL,
	@pattern_is BIT = 0,
	@pattern_office_id INT = NULL,
	@supplier_is BIT = 0,
	@supplier_id INT = NULL,
	@sa2 VARCHAR(36) = NULL,
	@rmt_id2 INT = NULL,
	@is_no_pa BIT = NULL,
	@season_id INT = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@technology_employee_id INT = NULL,
	@is_china BIT = NULL,
	@sls_id TINYINT = NULL,
	@construction_sale BIT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	DECLARE @rmt_tab TABLE (rmt_id INT)
	
	IF @rmt_id2 IS NOT NULL
	BEGIN
	    ;
	    WITH cte AS (
	    	SELECT	rmt.rmt_id,
	    			rmt.rmt_pid
	    	FROM	Material.RawMaterialType rmt
	    	WHERE	rmt.rmt_id = @rmt_id2
	    	UNION ALL
	    	SELECT	rmt.rmt_id,
	    			rmt.rmt_pid
	    	FROM	Material.RawMaterialType rmt   
	    			INNER JOIN	cte c
	    				ON	rmt.rmt_pid = c.rmt_id
	    )
	    INSERT INTO @rmt_tab
	    	(
	    		rmt_id
	    	)
	    SELECT	c.rmt_id
	    FROM	cte c
	END
	
	
	SELECT	s.sketch_id,
			s.st_id,
			st.st_name,
			s.ss_id,
			ss.ss_name,
			s.pic_count,
			s.tech_design,
			s.is_deleted,
			s.kind_id,
			k.kind_name,
			s.subject_id,
			s2.subject_name,
			s.create_employee_id,
			s.create_dt,
			s.employee_id,
			s.dt,
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
			s.imt_name,
			CAST(CAST(s.rv AS BIGINT) AS VARCHAR(19))     rv_bigint,
			s.constructor_employee_id,
			oa_p.x office_pattern,
			oa_sp.sp_id,
			oa_sp.plan_year,
			oa_sp.plan_month,
			oa_sp.ps_name,
			CAST(s.specification_dt AS DATETIME) specification_dt,
			sl.season_local_name,
			s.season_model_year,
			CAST(s.in_constructor_dt AS DATETIME) in_constructor_dt,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			esc.employee_name     constructor_employee_name,
			est.employee_name     technology_employee_name,
			CAST(s.technology_dt AS DATETIME) technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt,
			oats.x                     ts,
			slsd.sls_name,
			slsd.sls_id,
			CASE 
			     WHEN scs.sketch_id IS NOT NULL THEN 1
			     ELSE 0
			END construction_sale,
			s.pt_id,
			pt.pt_name
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
				ON sl.season_local_id = s.season_local_id
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	s.constructor_employee_id = esc.employee_id   
			LEFT JOIN	Settings.EmployeeSetting est
				ON	s.technology_employee_id = est.employee_id 
			LEFT JOIN Products.SketchLogicStatusDict slsd
				ON slsd.sls_id = s.sls_id
			LEFT JOIN Products.SketchConstructionSale scs
				ON scs.sketch_id = s.sketch_id
			LEFT JOIN Products.ProductType pt
				ON pt.pt_id = s.pt_id
			OUTER APPLY (
			      	SELECT	os.office_name + '; '
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
			OUTER APPLY (
			      	SELECT	TOP(1) sp.sp_id,
			      			sp.plan_year,
			      			sp.plan_month,
			      			ps.ps_name
			      	FROM	Planing.SketchPlan sp   
			      			INNER JOIN	Planing.PlanStatus ps
			      				ON	ps.ps_id = sp.ps_id
			      	WHERE sp.sketch_id = s.sketch_id
			      	ORDER BY
			      		sp.sp_id DESC
			      ) oa_sp
			OUTER APPLY (
			      	SELECT	ts.ts_name + ';'
			      	FROM	Products.SketchTechSize sts   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = sts.ts_id
			      	WHERE	sts.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oats(x)
	WHERE	(@ss_id IS NULL OR s.ss_id = @ss_id)
			AND	s.is_deleted = @is_deleted
			AND	(@creator_employee_id IS NULL OR s.create_employee_id = @creator_employee_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND	(@constructor_employee_id IS NULL OR s.constructor_employee_id = @constructor_employee_id OR (s.constructor_employee_id IS NULL AND @constructor_employee_id = 0))
			AND	(@sa IS NULL OR s.sa LIKE '%' + @sa + '%')
			AND	(@sa2 IS NULL OR @sa2 LIKE '%' + s.sa + '%')
			AND (@ct_id IS NULL OR s.ct_id = @ct_id)
			AND (@season_id IS NULL OR s.season_id = @season_id)
			AND (@season_local_id IS NULL OR s.season_local_id = @season_local_id)
			AND (@model_year IS NULL OR s.season_model_year = @model_year)
			AND (@technology_employee_id IS NULL OR s.technology_employee_id = technology_employee_id)
			AND (@is_china IS NULL OR s.is_china_sample = @is_china)
			AND (@sls_id IS NULL OR s.sls_id = @sls_id)
			AND (@construction_sale IS NULL OR (@construction_sale = 1 AND scs.sketch_id IS NOT NULL) OR (@construction_sale = 0 AND scs.sketch_id IS NULL))
			AND (
			    	@is_no_pa IS NULL
			    	OR (
			    	   	@is_no_pa = 1
			    	   	AND NOT EXISTS(
			    	   	    	SELECT	1
			    	   	    	FROM	Products.ProdArticle pa
			    	   	    	WHERE	pa.sketch_id = s.sketch_id
			    	   	    			AND	pa.is_deleted = 0
			    	   	    )
			    	   )
			    	OR (
			    	   	@is_no_pa = 0
			    	   	AND EXISTS(
			    	   	    	SELECT	1
			    	   	    	FROM	Products.ProdArticle pa
			    	   	    	WHERE	pa.sketch_id = s.sketch_id
			    	   	    			AND	pa.is_deleted = 0
			    	   	    )
			    	   )
			    )
			AND	(
			   		@nm_id IS NULL
			   		OR EXISTS(
			   		   	SELECT	1
			   		   	FROM	Products.ProdArticle pa   
			   		   			INNER JOIN	Products.ProdArticleNomenclature pan
			   		   				ON	pan.pa_id = pa.pa_id
			   		   	WHERE	pa.sketch_id = s.sketch_id
			   		   			AND	pan.nm_id = @nm_id
			   		)
			   		OR EXISTS(
			   		   	SELECT	1
			   		   	FROM	Products.ERP_IMT_Sketch eis   
			   		   			INNER JOIN	Products.ERP_NM_Sketch ens
			   		   				ON ens.imt_id = eis.imt_id
			   		   	WHERE	eis.sketch_id = s.sketch_id
			   		   			AND	ens.nm_id = @nm_id
			   		   )
			)
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
			AND (
			    	@rmt_id2 IS NULL
			    	OR EXISTS (
			    	   	SELECT	TOP(1) 1
			    	   	FROM	Products.SketchCompleting sc2   
			    	   			LEFT JOIN	Products.SketchCompletingRawMaterial scrm2
			    	   				ON	scrm2.sc_id = sc2.sc_id
			    	   	WHERE	sc2.sketch_id = s.sketch_id
			    	   			AND sc2.is_deleted = 0
			    	   			AND	EXISTS (
			    	   			   		SELECT	TOP(1) 1
			    	   			   		FROM	@rmt_tab rt2
			    	   			   		WHERE	rt2.rmt_id = sc2.base_rmt_id
			    	   			   				OR	rt2.rmt_id = scrm2.rmt_id
			    	   			   	)
			    	   )
			    )
			AND (
			    	@pattern_is = 0
			    	OR (
			    	   	@pattern_is = 1
			    	   	AND @pattern_office_id IS NOT NULL
			    	   	AND EXISTS (
			    	   	    	SELECT	TOP(1) 1
			    	   	    	FROM	Products.SketchBranchOfficePattern sbop
			    	   	    	WHERE	sbop.sketch_id = s.sketch_id
			    	   	    			AND	sbop.office_id = @pattern_office_id
			    	   	    )
			    	   	OR (
			    	   	   	@pattern_is = 1
			    	   	   	AND @pattern_office_id IS NULL
			    	   	   	AND NOT EXISTS(
			    	   	   	    	SELECT	TOP(1) 1
			    	   	   	    	FROM	Products.SketchBranchOfficePattern sbop
			    	   	   	    	WHERE	sbop.sketch_id = s.sketch_id
			    	   	   	    )
			    	   	   )
			    	   )
			)
			AND (
			    	@supplier_is = 0
			    	OR (
			    	   	@supplier_is = 1
			    	   	AND EXISTS (
			    	   	    	SELECT	TOP(1) 1
			    	   	    	FROM	Planing.SketchPlan sp   
			    	   	    			INNER JOIN	Planing.SketchPlanSupplierPrice spsp
			    	   	    				ON	spsp.sp_id = sp.sp_id
			    	   	    	WHERE	sp.sketch_id = s.sketch_id
			    	   	    			AND	(@supplier_id IS NULL
			    	   	    			OR	spsp.supplier_id = @supplier_id)
			    	   	    )
			    	   )
			    )
	ORDER BY
		s.sketch_id DESC