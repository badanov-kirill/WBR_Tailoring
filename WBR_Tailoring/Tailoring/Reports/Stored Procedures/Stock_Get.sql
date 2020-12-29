CREATE PROCEDURE [Reports].[Stock_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pants.pants_id,
			pa.sa + pan.sa             sa_name,
			ts.ts_name,
			pan.whprice,
			pan.price_ru price,
			COUNT(1)                   qty,
			pan.nm_id,
			b.brand_name,
			sj.subject_name
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
			INNER JOIN Products.Brand b
				ON b.brand_id = pa.brand_id
			INNER JOIN Products.[Subject] sj
				ON sj.subject_id = s.subject_id  
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = pbd.packing_box_id   
			--INNER JOIN	Warehouse.PackingBoxOnPlace pbop
			--	ON	pbd.packing_box_id = pbop.packing_box_id   
			--INNER JOIN	Warehouse.StoragePlace sp
			--	ON	sp.place_id = pbop.place_id   
			--INNER JOIN	Warehouse.ZoneOfResponse zor
			--	ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	WHERE	psfppb.packing_box_id IS NULL
			AND	sfppb.packing_box_id IS NULL
			AND	pb.close_dt IS NOT     NULL
	GROUP BY
		pants.pants_id,
		pa.sa,
		pan.sa,
		ts.ts_name,
		pan.whprice,
		pan.price_ru,
		pan.nm_id,
		b.brand_name,
		sj.subject_name