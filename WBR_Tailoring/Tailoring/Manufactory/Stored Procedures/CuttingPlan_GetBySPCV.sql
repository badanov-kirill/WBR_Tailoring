CREATE PROCEDURE [Manufactory].[CuttingPlan_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	cmp.cutting_id,
			cmp.perimeter,
			ts.ts_name,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			s.pt_id,
			pt.pt_name,
			cmp.plan_year,
			cmp.plan_month,
			CAST(cmp.planing_dt AS DATETIME) planing_dt,
			CAST(cmp.plan_start_dt AS DATETIME) plan_start_dt,
			oa_empl.employee_xml,
			cmp.plan_count,
			ISNULL(oa_ac.actual_count, 0) actual_count,
			ISNULL(oa_oc.print_label, 0)     print_label,
			ISNULL(oa_oc.launch_of, 0)       launch_of,
			ISNULL(oa_oc.on_packaging, 0) on_packaging,
			ISNULL(oa_oc.in_remaking, 0)     in_remaking,
			ISNULL(oa_oc.write_off, 0)       write_off,
			ISNULL(oa_oc.change_article, 0) change_article,
			ISNULL(oa_oc.for_special_equipment, 0) for_special_equipment,
			ISNULL(oa_oc.packaging_after_se, 0) packaging_after_se,
			ISNULL(oa_oc.packaging, 0)       packaging,
			ISNULL(oa_oc.repaired, 0)        repaired,
			ISNULL(oa_oc.pre_cut_write_off, 0) pre_cut_write_off,
			ISNULL(oa_oc.cut_write_off, 0) cut_write_off
	FROM	Manufactory.Cutting cmp   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = cmp.spcvts_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = cmp.pants_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			OUTER APPLY (
			      	SELECT	ce.employee_id '@id'
			      	FROM	Manufactory.CuttingEmployee ce
			      	WHERE	ce.cutting_id = cmp.cutting_id
			      	FOR XML	PATH('empl'), ROOT('employes')
			      ) oa_empl(employee_xml)OUTER APPLY (
			                                   	SELECT	SUM(ca.actual_count) actual_count
			                                   	FROM	Manufactory.CuttingActual ca
			                                   	WHERE	ca.cutting_id = cmp.cutting_id
			                                   ) oa_ac
	OUTER APPLY (
	      	SELECT	SUM(CASE WHEN puc.operation_id = 7 THEN 1 ELSE 0 END) print_label,
	      			SUM(CASE WHEN puc.operation_id = 9 THEN 1 ELSE 0 END) launch_of,
	      			SUM(CASE WHEN puc.operation_id = 1 THEN 1 ELSE 0 END) on_packaging,
	      			SUM(CASE WHEN puc.operation_id = 2 THEN 1 ELSE 0 END) in_remaking,
	      			SUM(CASE WHEN puc.operation_id = 3 THEN 1 ELSE 0 END) write_off,
	      			SUM(CASE WHEN puc.operation_id = 4 THEN 1 ELSE 0 END) change_article,
	      			SUM(CASE WHEN puc.operation_id = 5 THEN 1 ELSE 0 END) for_special_equipment,
	      			SUM(CASE WHEN puc.operation_id = 6 THEN 1 ELSE 0 END) packaging_after_se,
	      			SUM(CASE WHEN puc.operation_id = 8 THEN 1 ELSE 0 END) packaging,
	      			SUM(CASE WHEN puc.operation_id = 10 THEN 1 ELSE 0 END) repaired,
	      			SUM(CASE WHEN puc.operation_id = 11 THEN 1 ELSE 0 END) pre_cut_write_off,
	      			SUM(CASE WHEN puc.operation_id = 12 THEN 1 ELSE 0 END) cut_write_off
	      	FROM	Manufactory.ProductUnicCode puc
	      	WHERE	puc.cutting_id = cmp.cutting_id
	      	GROUP BY
	      		puc.cutting_id
	      )                                  oa_oc
	WHERE	spcvt.spcv_id = @spcv_id
			AND	cmp.plan_count > 0
	ORDER BY
		ts.ts_name