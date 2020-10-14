CREATE PROCEDURE [Reports].[FinishedProducts]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa                         sa_imt,
			pan.sa                        sa_nm,
			ts.ts_name,
			pa.sketch_id,
			k.kind_name,
			pan.whprice,
			pan.price_ru,
			CAST(spcv.deadline_package_dt AS DATETIME)     deadline_package_dt,
			pbd.barcode barcode,
			pb.packing_box_id,
			os.office_name,
			sp.place_name,
			CAST(pb.close_dt AS DATETIME) close_dt,
			CAST(pbop.dt AS DATETIME)     place_dt,
			CAST(CASE 
			     WHEN psfppb.packing_box_id IS NOT NULL THEN 1
			     ELSE 0
			END AS BIT)                          plan_shipping,
			CAST(CASE 
			     WHEN sfppb.packing_box_id IS NOT NULL THEN 1
			     ELSE 0
			END  AS BIT)                         shipping,
			puc.dt
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	puc.product_unic_code = pbd.product_unic_code   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants   
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
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id
				ON	pants.pants_id = puc.pants_id   
			LEFT JOIN	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id
				ON	spcvt.spcvts_id = c.spcvts_id
				ON	c.cutting_id = puc.cutting_id   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = pbd.packing_box_id   
			LEFT JOIN	Warehouse.PackingBoxOnPlace pbop
				ON	pbd.packing_box_id = pbop.packing_box_id   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	WHERE	puc.dt > @start_dt
			AND	puc.dt < DATEADD(DAY, 1, @finish_dt)
			AND puc.operation_id = 8
