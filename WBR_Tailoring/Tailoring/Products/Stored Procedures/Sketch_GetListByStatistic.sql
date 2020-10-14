CREATE PROCEDURE [Products].[Sketch_GetListByStatistic]
	@ss_id INT = NULL,
	@is_deleted BIT = 0,
	@creator_employee_id INT = NULL,
	@brand_id INT = NULL,
	@art_name VARCHAR(100) = NULL,
	@subject_id INT = NULL,
	@nm_id INT = NULL,
	@sa VARCHAR(36) = NULL,
	@constructor_employee_id INT = NULL,
	@sale_qty_min INT = NULL,
	@sale_amount_min DECIMAL(15, 2) = NULL,
	@turnover_min INT = NULL,
	@effective_percent_discount_min INT = NULL,
	@income_qty_min INT = NULL,
	@sale_qty_max INT = NULL,
	@sale_amount_max DECIMAL(15, 2) = NULL,
	@turnover_max INT = NULL,
	@effective_percent_discount_max INT = NULL,
	@income_qty_max INT = NULL,
	@ct_id INT = NULL,
	@pattern_is BIT = 0,
	@pattern_office_id INT = NULL,
	@supplier_is BIT = 0,
	@supplier_id INT = NULL,
	@is_no_pa BIT = NULL,
	@season_id INT = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@is_china BIT = NULL
AS
	SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
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
			CAST(CAST(s.rv AS BIGINT) AS VARCHAR(19)) rv_bigint,
			s.constructor_employee_id,
			oa_st.sale_qty,
			oa_st.sale_amount,
			oa_st.turnover,
			oa_st.effective_percent_discount,
			oa_st.income_qty,
			oa_p.x office_pattern,
			oa_sp.sp_id,
			oa_sp.plan_year,
			oa_sp.plan_month,
			oa_sp.ps_name,
			sl.season_local_name,
			s.season_model_year,
			CAST(s.in_constructor_dt AS DATETIME) in_constructor_dt,
			CAST(s.construction_close_dt AS DATETIME) construction_close_dt,
			s.technology_dt,
			CAST(s.plan_site_dt AS DATETIME) plan_site_dt
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
			      ) oa_st
			OUTER APPLY (
			      	SELECT	os.office_name + ';'
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	WHERE	(@ss_id IS NULL OR s.ss_id = @ss_id)
			AND	s.is_deleted = @is_deleted
			AND	(@creator_employee_id IS NULL OR s.create_employee_id = @creator_employee_id)
			AND	(@brand_id IS NULL OR s.brand_id = @brand_id)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	(@subject_id IS NULL OR s.subject_id = @subject_id)
			AND (@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(
			   		@constructor_employee_id IS NULL
			   		OR s.constructor_employee_id = @constructor_employee_id
			   		OR (s.constructor_employee_id IS NULL AND @constructor_employee_id = 0)
			   	)
			AND	(@sa IS NULL OR s.sa LIKE @sa + '%')
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
			)
			AND (@sale_qty_min IS NULL OR oa_st.sale_qty >= @sale_qty_min)
			AND (@sale_qty_max IS NULL OR oa_st.sale_qty <= @sale_qty_max)
			AND (@sale_amount_min IS NULL OR oa_st.sale_amount >= @sale_amount_min)
			AND (@sale_amount_max IS NULL OR oa_st.sale_amount <= @sale_amount_max)
			AND (@turnover_min IS NULL OR oa_st.turnover >= @turnover_min)
			AND (@turnover_max IS NULL OR oa_st.turnover <= @turnover_max)
			AND (@effective_percent_discount_min IS NULL OR oa_st.effective_percent_discount >= @effective_percent_discount_min)
			AND (@effective_percent_discount_max IS NULL OR oa_st.effective_percent_discount <= @effective_percent_discount_max)
			AND (@income_qty_min IS NULL OR oa_st.income_qty >= @income_qty_min)
			AND (@income_qty_max IS NULL OR oa_st.income_qty <= @income_qty_max)
			AND (@season_local_id IS NULL OR s.season_local_id = @season_local_id)
			AND (@model_year IS NULL OR s.season_model_year = @model_year)	
			AND (@is_china IS NULL OR s.is_china_sample = @is_china)
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
		AND (@season_id IS NULL OR s.season_id = @season_id)
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
	ORDER BY
		s.qp_id ASC,
		s.sketch_id ASC