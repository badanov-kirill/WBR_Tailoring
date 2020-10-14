CREATE PROCEDURE [Planing].[SketchPlan_GetFomSidedTailoringManager]
	@supplier_id INT = NULL,
	@order_num VARCHAR(10) = NULL,
	@art_name VARCHAR(50) = NULL,
	@is_china_sample BIT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @status_sided_tailoring TINYINT = 9
	DECLARE @status_sided_order_is_signed TINYINT = 11
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			sp.ps_id,
			ps.ps_name,
			s.st_id,
			sp.create_employee_id       planing_employee_id,
			CAST(sp.create_dt AS DATETIME) planing_dt,
			s.pic_count,
			s.tech_design,
			ISNULL(s.imt_name, s2.subject_name_sf) subject_name,
			an.art_name,
			s.brand_id,
			b.brand_name,
			s.sa_local,
			s.sa,
			s.constructor_employee_id,
			sp.comment,
			ct.ct_name,
			oa.supplier_name,
			CAST(sp.dt AS DATETIME)     dt,
			oac.is_consumtion,
			oa.price_ru,
			oa.order_num,
			s.descr,
			oa.comment                  price_comment,
			oats.x                      ts,
			sp.plan_year,
			sp.plan_month
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
			      	SELECT	TOP(1) sup.supplier_name,
			      			spsp.price_ru,
			      			spsp.order_num,
			      			spsp.supplier_id,
			      			spsp.comment
			      	FROM	Planing.SketchPlanSupplierPrice spsp   
			      			INNER JOIN	Suppliers.Supplier sup
			      				ON	sup.supplier_id = spsp.supplier_id
			      	WHERE	spsp.sp_id = sp.sp_id
			      	ORDER BY
			      		CASE 
			      		     WHEN spsp.price_ru = 0 THEN 1
			      		     ELSE 0
			      		END,
			      		spsp.price_ru ASC
			      ) oa
	OUTER APPLY (
	      	SELECT	ts.ts_name + ';'
	      	FROM	Products.SketchTechSize sts   
	      			INNER JOIN	Products.TechSize ts
	      				ON	ts.ts_id = sts.ts_id
	      	WHERE	sts.sketch_id = s.sketch_id
	      	FOR XML	PATH('')
	      ) oats(x)OUTER APPLY (
	                     	SELECT	TOP(1) 1 is_consumtion
	                     	FROM	Products.SketchCompleting sc
	                     	WHERE	sc.sketch_id = sp.sketch_id
	                     			AND	sc.consumption > 0
	                     )              oac
	WHERE	(
	     		(sp.ps_id IN (@status_sided_tailoring, @status_sided_order_is_signed) AND s.is_china_sample = @is_china_sample)
	     	)
			AND	(@supplier_id IS NULL OR @supplier_id = oa.supplier_id)
			AND	(@order_num IS NULL OR @order_num = oa.order_num)
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND s.is_deleted = 0
