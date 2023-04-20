CREATE PROCEDURE [Planing].[SketchPlan_GetForManager]
	@employee_id INT = NULL,
	@rmt_id INT = NULL,
	@ct_id INT = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL,
	@brand_id INT = NULL,
	@rmt_id2 INT = NULL,
	@for_pre_plan BIT = 0,
	@season_local_id INT = NULL,
	@supplier_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @states_approve TINYINT = 2
	DECLARE @status_bayer_to_designer TINYINT = 6
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
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			sp.ps_id,
			ps.ps_name,
			s.st_id,
			sp.create_employee_id       planing_employee_id,
			CAST(sp.create_dt AS DATETIME) planing_dt,
			st.st_name,
			s.ss_id,
			ss.ss_name,
			s.pic_count,
			s.tech_design,
			s2.subject_name,
			an.art_name,
			s.brand_id,
			b.brand_name,
			s.sa_local,
			s.sa,
			s.constructor_employee_id,
			oa_st.sale_qty,
			oa_st.sale_amount,
			oa_st.turnover,
			oa_st.effective_percent_discount,
			oa_st.income_qty,
			ISNULL(sp.comment, '') + ISNULL(oa_c.x, '') comment,
			CAST(sp.dt AS DATETIME)     dt,
			sp.plan_year, 
			sp.plan_month,
			oa_sup.supplier_name,
			sp.qp_id,
			qp.qp_name,
			sp.plan_qty, 
			sp.cv_qty,
			os.office_name sew_office_name,
			CAST(sp.plan_sew_dt AS DATETIME) plan_sew_dt,
			sup.supplier_name sp_supplier_name,
			sp.sew_fabricator_id,
			f.fabricator_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			LEFT JOIN Settings.Fabricators f
				ON f.fabricator_id = sp.sew_fabricator_id
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   
			INNER JOIN	Products.SketchType st
				ON	st.st_id = s.st_id   
			INNER JOIN	Products.[Subject] s2
				ON	s2.subject_id = s.subject_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id  
			INNER JOIN Products.QueuePriority qp
				ON qp.qp_id = sp.qp_id 
			LEFT JOIN Settings.OfficeSetting os
				ON os.office_id = sp.sew_office_id
			LEFT JOIN Suppliers.Supplier sup
				ON sp.supplier_id = sup.supplier_id
			OUTER APPLY (
			      	SELECT	SUM(ns.sale_qty) sale_qty,
			      			SUM(ns.sale_amount) sale_amount,
			      			MIN(ns.turnover) turnover,
			      			AVG(ns.effective_percent_discount) effective_percent_discount,
			      			SUM(ns.income_qty) income_qty
			      	FROM	Products.Nomenclature_Statistics ns   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.nm_id = ns.nm_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id
			      	WHERE	pa.sketch_id = s.sketch_id
			      )                     oa_st
			OUTER APPLY (
			      	SELECT	TOP(1) sup.supplier_name
			      	FROM	Planing.SketchPlanSupplierPrice spsp   
			      			INNER JOIN	Planing.SketchPlan sp2
			      				ON	sp2.sp_id = spsp.sp_id   
			      			INNER JOIN	Suppliers.Supplier sup
			      				ON	sup.supplier_id = spsp.supplier_id
			      	WHERE	sp2.sketch_id = sp.sketch_id
			      	ORDER BY
			      		spsp.spsp_id DESC
			      ) oa_sup
			OUTER APPLY (
					SELECT sppc.comment + ' | '
					FROM Planing.SketchPrePlanComment sppc
					WHERE sppc.spp_id = sp.spp_id
					FOR XML PATH('')
			) oa_c(x)
	WHERE	sp.ps_id IN (@states_approve, @status_bayer_to_designer)
			AND	(@employee_id IS NULL OR sp.create_employee_id = @employee_id)
			AND (@ct_id IS NULL OR s.ct_id = @ct_id)
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
			   		OR EXISTS (
			   		   	SELECT	TOP(1) 1
			   		   	FROM	Planing.SketchPlanColorVariant spcv   
			   		   			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
			   		   				ON	spcvc.spcv_id = spcv.spcv_id
			   		   	WHERE	spcv.sp_id = sp.sp_id
			   		   			AND	spcvc.rmt_id = @rmt_id
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
			    	OR EXISTS (
			   		   	SELECT	TOP(1) 1
			   		   	FROM	Planing.SketchPlanColorVariant spcv2   
			   		   			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc2
			   		   				ON	spcvc2.spcv_id = spcv2.spcv_id
			   		   	WHERE	spcv2.sp_id = sp.sp_id
			   		   			AND	EXISTS (
			    	   			   		SELECT	TOP(1) 1
			    	   			   		FROM	@rmt_tab rt3
			    	   			   		WHERE	rt3.rmt_id = spcvc2.rmt_id
			    	   			   	)
			   		   )
			    )
			AND (@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND (@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND (@brand_id IS NULL OR s.brand_id = @brand_id)
			AND (@for_pre_plan IS NULL OR (@for_pre_plan = 0 AND sp.spp_id IS NULL) OR (@for_pre_plan = 1 AND sp.spp_id IS NOT NULL))
			AND (@season_local_id IS NULL OR sp.season_local_id = @season_local_id)
			AND (
			    	@supplier_id IS NULL
			    	OR sp.supplier_id = @supplier_id
			    	OR EXISTS(
			    	   	SELECT	TOP(1) 1
			    	   	FROM	Planing.SketchPlanColorVariant spcv3   
			    	   			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc3
			    	   				ON	spcvc3.spcv_id = spcv3.spcv_id
			    	   	WHERE	spcv3.sp_id = sp.sp_id
			    	   			AND	spcvc3.supplier_id = @supplier_id
			    	   )
			    )
	ORDER BY an.art_name, sp.sp_id