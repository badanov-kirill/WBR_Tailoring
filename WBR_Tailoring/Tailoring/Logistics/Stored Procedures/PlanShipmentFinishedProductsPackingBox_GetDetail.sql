CREATE PROCEDURE [Logistics].[PlanShipmentFinishedProductsPackingBox_GetDetail]
	@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	os.office_name,
			sp.place_name,
			pbop.packing_box_id,
			CAST(pb.start_packaging_dt AS DATETIME) start_packaging_dt,
			CAST(pb.close_dt AS DATETIME) close_dt,
			CAST(pbop.dt AS DATETIME) place_dt
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = psfppb.packing_box_id   
			LEFT JOIN	Warehouse.PackingBoxOnPlace pbop
				ON	psfppb.packing_box_id = pbop.packing_box_id   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
	WHERE	psfppb.sfp_id = @sfp_id
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa                 sa_imt,
			pan.sa                sa_nm,
			ts.ts_name,
			pa.sketch_id,
			k.kind_name,
			pan.whprice,
			pan.price_ru,
			COUNT(pbd.pbd_id)     cnt
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.packing_box_id = psfppb.packing_box_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pbd.product_unic_code   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
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
	WHERE	psfppb.sfp_id = @sfp_id
	GROUP BY
		b.brand_name,
		sj.subject_name,
		an.art_name,
		pa.sa,
		pan.sa,
		ts.ts_name,
		pa.sketch_id,
		k.kind_name,
		pan.whprice,
		pan.price_ru
	ORDER BY
		b.brand_name,
		pa.sa,
		pan.sa,
		ts.ts_name
		