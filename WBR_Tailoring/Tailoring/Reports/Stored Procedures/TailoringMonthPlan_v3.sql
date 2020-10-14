CREATE PROCEDURE [Reports].[TailoringMonthPlan_v3]
	@office_id INT = NULL,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	SELECT	cmp.office_id,
			bo.office_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			pan.nm_id,
			pa.sa + pan.sa                 article,
			an.art_name,
			ct.ct_name,
			SUM(spcvt.cnt)                 plan_count,
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
			SUM(ISNULL(oa_oc.repaired, 0)) repaired,
			SUM(ISNULL(oa_oc.pre_cut_write_off, 0)) pre_cut_write_off,
			SUM(ISNULL(oa_oc.cut_write_off, 0)) cut_write_off,
			MAX(CAST(cmp.plan_start_dt AS DATETIME)) plan_start_dt,
			MAX(DATEDIFF(DAY, cmp.plan_start_dt, GETDATE())) AS day_after_start,
			CAST(spcv.deadline_package_dt AS DATETIME) deadline_package_dt,
			CAST(spcv.sew_deadline_dt AS DATETIME) sew_deadline_dt,
			s.season_model_year,
			sl.season_local_name,
			coll.collection_name,
			MIN(oa_oc.shipping_dt) shipping_dt
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = spcv.spcv_id   
			INNER JOIN	Manufactory.Cutting cmp
				ON	cmp.spcvts_id = spcvt.spcvts_id   
			INNER JOIN	Settings.OfficeSetting bo
				ON	bo.office_id = spcv.sew_office_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			LEFT JOIN Products.SeasonLocal sl
				ON sl.season_local_id = s.season_local_id
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand  AS b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize AS ts
				ON	ts.ts_id = spcvt.ts_id   
			LEFT JOIN Products.[Collection] coll 
				ON coll.collection_id = pa.collection_id 
			LEFT JOIN	(SELECT	ca.cutting_id,
			    	    	 		SUM(ca.actual_count) actual_count
			    	    	 FROM	Manufactory.CuttingActual ca
			    	    	 GROUP BY
			    	    	 	ca.cutting_id)oa_ac
				ON	oa_ac.cutting_id = cmp.cutting_id   
			LEFT JOIN	(SELECT	puc.cutting_id,
			    	    	 		SUM(CASE WHEN puc.operation_id = 7 THEN 1 ELSE 0 END) print_label,
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
			    	    	 		SUM(CASE WHEN puc.operation_id = 12 THEN 1 ELSE 0 END) cut_write_off,
			    	    	 		CAST(MIN(sfp.complite_dt) AS DATETIME) shipping_dt
			    	    	 FROM	Manufactory.ProductUnicCode puc
			    	    	 LEFT JOIN Logistics.TransferBoxDetail tbd 
			    	    		INNER JOIN	Logistics.ShipmentFinishedProductsDetail sfpd
		    	    	 			ON	sfpd.transfer_box_id = tbd.transfer_box_id   
		    	    	 		INNER JOIN	Logistics.ShipmentFinishedProducts sfp
		    	    	 			ON	sfp.sfp_id = sfpd.sfp_id			    	    	 
			    	    	 ON tbd.product_unic_code = puc.product_unic_code
			    	    	 
			    	    	 GROUP BY
			    	    	 	puc.cutting_id)oa_oc
				ON	oa_oc.cutting_id = cmp.cutting_id
	WHERE	(@office_id IS NULL OR spcv.sew_office_id = @office_id)
			AND	spcv.cost_plan_year >= YEAR(@start_dt)
			AND	spcv.cost_plan_month >= MONTH(@start_dt)
			AND	spcv.cost_plan_year <= YEAR(@finish_dt)
			AND	spcv.cost_plan_month <= MONTH(@finish_dt)
			AND DATEFROMPARTS(spcv.cost_plan_year, spcv.cost_plan_month, 1) BETWEEN @start_dt AND @finish_dt
			AND	(spcvt.cnt > 0 OR oa_ac.actual_count > 0)
	GROUP BY
		cmp.office_id,
		bo.office_name,
		ISNULL(s.imt_name, sj.subject_name_sf),
		b.brand_name,
		pan.nm_id,
		pa.sa + pan.sa,
		an.art_name,
		ct.ct_name,
		spcv.deadline_package_dt,
		s.season_model_year,
		sl.season_local_name,
		coll.collection_name,
		spcv.sew_deadline_dt