CREATE PROCEDURE [Reports].[SketchPlanColorVariantForPayment]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	SELECT	sp.sp_id,
			sp.sketch_id,
			s.sa_local,
			an.art_name,
			sj.subject_name,
			spcv.spcv_name,
			spcv.qty,
			b.brand_name,
			ct.ct_name,
			oa_p.x office_pattern,
			oa_cvc.sum_amount,
			CAST(oa_cvc.max_supply_dt AS DATETIME) max_supply_dt,
			CAST(spcv.begin_plan_delivery_dt AS DATETIME) begin_plan_delivery_dt,
			CAST(spcv.end_plan_delivery_dt AS DATETIME) end_plan_delivery_dt,
			os.office_name,
			sp.plan_year,
			sp.plan_month,
			spcv.spcv_id
	FROM	Planing.SketchPlan sp   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.sp_id = sp.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = s.ct_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			INNER JOIN	(SELECT	spcv.sp_id,
			    	     	 		SUM(spcv.qty) qty
			    	     	 FROM	Planing.SketchPlanColorVariant spcv
			    	     	 WHERE	spcv.is_deleted = 0
			    	     	 GROUP BY
			    	     	 	spcv.sp_id)oa_cv
				ON	oa_cv.sp_id = sp.sp_id   
			INNER JOIN	(SELECT	spcvc.spcv_id,
			    	     	 		SUM(rmodfr.qty * rmodfr.price_cur * c.rate_absolute) sum_amount,
			    	     	 		MAX(rmo.supply_dt) max_supply_dt
			    	     	 FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			    	     	 		INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
			    	     	 			ON	rmsr.spcvc_id = spcvc.spcvc_id   
			    	     	 		INNER JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			    	     	 			ON	rmodfr.rmsr_id = rmsr.rmsr_id   
			    	     	 		INNER JOIN	Suppliers.RawMaterialOrder rmo
			    	     	 			ON	rmo.rmo_id = rmodfr.rmo_id   
			    	     	 		INNER JOIN	RefBook.Currency c
			    	     	 			ON	c.currency_id = rmodfr.currency_id
			    	     	 GROUP BY
			    	     	 	spcvc.spcv_id)oa_cvc
				ON	oa_cvc.spcv_id = spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	os.office_name + ';'
			      	FROM	Products.SketchBranchOfficePattern sbop   
			      			INNER JOIN	Settings.OfficeSetting os
			      				ON	os.office_id = sbop.office_id
			      	WHERE	sbop.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) oa_p(x)
	WHERE	spcv.cvs_id = @cv_status_ready
			AND	spcv.is_deleted = 0
			AND	oa_cvc.max_supply_dt >= @start_dt
			AND	oa_cvc.max_supply_dt <= @finish_dt
	ORDER BY
		oa_cvc.max_supply_dt,
		sp.sp_id,
		spcv.spcv_name