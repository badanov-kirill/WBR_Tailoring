CREATE PROCEDURE [Planing].[SketchPlan_GetForRuler]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @status_add TINYINT = 1
	DECLARE @status_addSM TINYINT = 13
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			sp.ps_id,
			ps.ps_name,
			s.st_id,
			sp.create_employee_id     planing_employee_id,
			es.employee_name          planing_employee_name,
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
			ces.employee_name			constructor_employee_name,
			oa_st.sale_qty,
			oa_st.sale_amount,
			oa_st.turnover,
			oa_st.effective_percent_discount,
			oa_st.income_qty,
			sp.comment,
			sp.plan_year,
			sp.plan_month,
			oa_p.x                    office_pattern,
			sp.plan_qty,
			sp.cv_qty,
			CAST(sp.plan_sew_dt AS DATETIME) plan_sew_dt,
			s.pt_id,
			pt.pt_name
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN Products.ProductType pt
				ON pt.pt_id = s.pt_id
			LEFT JOIN Settings.EmployeeSetting es
				ON sp.create_employee_id = es.employee_id
			LEFT JOIN Settings.EmployeeSetting ces
				ON s.constructor_employee_id = ces.employee_id	
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
	      			SELECT	os.office_name + '; '
	      			FROM	Products.SketchBranchOfficePattern sbop   
	      					INNER JOIN	Settings.OfficeSetting os
	      						ON	os.office_id = sbop.office_id
	      			WHERE	sbop.sketch_id = s.sketch_id
	      			FOR XML	PATH('')
				  ) oa_p(x)
	WHERE	sp.ps_id IN (@status_add, @status_addSM)