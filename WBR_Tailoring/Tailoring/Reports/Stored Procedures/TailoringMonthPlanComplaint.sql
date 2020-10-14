CREATE PROCEDURE [Reports].[TailoringMonthPlanComplaint]
	@office_id INT = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.completing_name + ' ' + CAST(sc.completing_number AS VARCHAR(10)) completing,
			rmt.rmt_name,
			sc.consumption,
			o.symbol okei_symbol,
			sc.consumption * v.plan_count plan_consumption,
			v.office_id,
			v.office_name,
			v.imt_name,
			v.brand_name,
			v.nm_id,
			v.article,
			v.art_name,
			v.plan_count,
			v.cutting,
			v.print_label,
			v.launch_of,
			v.on_packaging,
			v.in_remaking,
			v.write_off,
			v.change_article,
			v.for_special_equipment,
			v.packaging_after_se,
			v.packaging,
			v.plan_start_dt,
			v.day_after_start
	FROM	(SELECT	pa.sketch_id,
	    	 		cmp.office_id,
	    	 		bo.office_name,
	    	 		ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
	    	 		b.brand_name,
	    	 		pan.nm_id,
	    	 		pa.sa + pan.sa          article,
	    	 		an.art_name,
	    	 		SUM(cmp.plan_count)     plan_count,
	    	 		SUM(ISNULL(oa_ac.actual_count, 0))cutting,
	    	 		SUM(ISNULL(oa_oc.print_label, 0)) print_label,
	    	 		SUM(ISNULL(oa_oc.launch_of, 0)) launch_of,
	    	 		SUM(ISNULL(oa_oc.on_packaging, 0)) on_packaging,
	    	 		SUM(ISNULL(oa_oc.in_remaking, 0)) in_remaking,
	    	 		SUM(ISNULL(oa_oc.write_off, 0)) write_off,
	    	 		SUM(ISNULL(oa_oc.change_article, 0)) change_article,
	    	 		SUM(ISNULL(oa_oc.for_special_equipment, 0)) for_special_equipment,
	    	 		SUM(ISNULL(oa_oc.packaging_after_se, 0)) packaging_after_se,
	    	 		SUM(ISNULL(oa_oc.packaging, 0)) packaging,
	    	 		MAX(CAST(cmp.plan_start_dt AS DATETIME)) plan_start_dt,
	    	 		MAX(DATEDIFF(DAY, cmp.plan_start_dt, GETDATE())) AS day_after_start
	    	 FROM	Manufactory.Cutting cmp   
	    	 		INNER JOIN	Settings.OfficeSetting bo
	    	 			ON	bo.office_id = cmp.office_id   
	    	 		INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
	    	 			ON	pants.pants_id = cmp.pants_id   
	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
	    	 			ON	pan.pan_id = pants.pan_id   
	    	 		INNER JOIN	Products.ProdArticle pa
	    	 			ON	pa.pa_id = pan.pa_id   
	    	 		INNER JOIN	Products.Sketch s
	    	 			ON	s.sketch_id = pa.sketch_id   
	    	 		INNER JOIN	Products.ArtName an
	    	 			ON	an.art_name_id = s.art_name_id   
	    	 		INNER JOIN	Products.[Subject] sj
	    	 			ON	sj.subject_id = s.subject_id   
	    	 		INNER JOIN	Products.Brand AS b
	    	 			ON	b.brand_id = pa.brand_id   
	    	 		INNER JOIN	Products.TechSize AS ts
	    	 			ON	ts.ts_id = pants.ts_id   
	    	 		OUTER APPLY (
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
	    	       			SUM(CASE WHEN puc.operation_id = 8 THEN 1 ELSE 0 END) packaging
	    	       	FROM	Manufactory.ProductUnicCode puc
	    	       	WHERE	puc.cutting_id = cmp.cutting_id
	    	       	GROUP BY
	    	       		puc.cutting_id
	    	       )                        oa_oc
	    	 WHERE	(@office_id IS NULL OR cmp.office_id = @office_id)
	    	 		AND	cmp.plan_year = @plan_year
	    	 		AND	cmp.plan_month = @plan_month
	    	 		AND (cmp.plan_count > 0 OR oa_ac.actual_count > 0)
	    	 GROUP BY
	    	 	pa.sketch_id,
	    	 	cmp.office_id,
	    	 	bo.office_name,
	    	 	ISNULL(s.imt_name, sj.subject_name_sf),
	    	 	b.brand_name,
	    	 	pan.nm_id,
	    	 	pa.sa + pan.sa,
	    	 	an.art_name)v   
			LEFT JOIN	Products.SketchCompleting sc
				ON	sc.sketch_id = v.sketch_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = sc.base_rmt_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	sc.okei_id = o.okei_id