CREATE PROCEDURE [Planing].[SketchPlan_Get]
	@employee_id INT = NULL,
	@psg_id TINYINT = NULL,
	@rmt_id INT = NULL,
	@ct_id INT = NULL,
	@plan_year SMALLINT = NULL,
	@plan_month TINYINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @completing_up INT = 4
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			sp.ps_id,
			ps.ps_name,
			s.st_id,
			sp.create_employee_id     planing_employee_id,
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
			sp.comment,
			ct.ct_name,
			s.ct_id,
			oa_cv.cnt                 cnt_cv,
			oa_cv.qty                 qty_cv,
			oa_rmt.rmt_name,
			sp.plan_year, 
			sp.plan_month,
			CAST(sp.to_purchase_dt AS DATETIME) to_purchase_dt
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
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
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
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
	      			SELECT	COUNT(spcv.spcv_id)     cnt,
	      					SUM(spcv.qty)           qty
	      			FROM	Planing.SketchPlanColorVariant spcv
	      			WHERE	spcv.sp_id = sp.sp_id
	      					AND	spcv.is_deleted = 0
				  ) oa_cv
			OUTER APPLY (
	      			SELECT	TOP(1) rmt.rmt_name
	      			FROM	Planing.SketchPlanColorVariant spcv   
	      					INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
	      						ON	spcvc.spcv_id = spcv.spcv_id   
	      					INNER JOIN	Material.RawMaterialType rmt
	      						ON	rmt.rmt_id = spcvc.rmt_id
	      			WHERE	spcv.sp_id = sp.sp_id
	      					AND	spcv.is_deleted = 0
	      					AND	spcvc.completing_id = @completing_up
	      					AND	spcvc.completing_number = 1
	      			ORDER BY
	      				spcvc.spcvc_id DESC
				  )                           oa_rmt
	WHERE	(@employee_id IS NULL OR sp.create_employee_id = @employee_id)
			AND	(@psg_id IS NULL OR ps.psg_id = @psg_id)
			AND (@ct_id IS NULL OR s.ct_id = @ct_id)
			AND	(@plan_year IS NULL OR sp.plan_year = @plan_year)
			AND	(@plan_month IS NULL OR sp.plan_month = @plan_month)
			AND	(
			   		@rmt_id IS NULL
			   		OR EXISTS (
			   		   	SELECT	TOP(1) 1
			   		   	FROM	Products.SketchCompleting sc   
			   		   			LEFT JOIN	Products.SketchCompletingRawMaterial scrm
			   		   				ON	scrm.sc_id = sc.sc_id
			   		   	WHERE	sc.sketch_id = s.sketch_id
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