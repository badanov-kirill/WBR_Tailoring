CREATE PROCEDURE [Reports].[ChestnyZnakUsed]
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
	SELECT	puc.packing_dt,
			pa.sa + pan.sa     sa,
			ts.ts_name,
			an.art_name,
			b.brand_name,
			sj.subject_name,
			oczdi.gtin01,
			oczdi.serial21,
			oczdi.intrnal91, 
			oczdi.intrnal92,
			pbd.packing_box_id,
			sfp.sfp_id,
			sup.supplier_name,
			oa_czic.dt_send       in_circulation_dt,
			oa_czoc.dt_create     out_circulation_dt
	FROM	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi   
			INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.oczdi_id = pucczi.oczdi_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pucczi.product_unic_code   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			LEFT JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.product_unic_code = puc.product_unic_code   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pbd.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProducts sfp
				ON	sfp.sfp_id = psfppb.sfp_id   
			LEFT JOIN	Suppliers.Supplier sup
				ON	sup.supplier_id = sfp.supplier_id   
			OUTER APPLY (SELECT TOP(1) czic.dt_send
			             FROM Manufactory.ChestnyZnakInCirculationDetail czicd
							LEFT JOIN	Manufactory.ChestnyZnakInCirculation czic
							ON	czic.czic_id = czicd.czic_id   
			             WHERE	czicd.oczdi_id = oczdi.oczdi_id
			             ORDER BY czic.dt_send ASC
			) oa_czic
			OUTER APPLY (
			      	SELECT	TOP(1) czoc.dt_create
			      	FROM	Manufactory.ChestnyZnakOutCirculationDetail czocd   
			      			LEFT JOIN	Manufactory.ChestnyZnakOutCirculation czoc
			      				ON	czoc.czoc_id = czocd.czoc_id
			      	WHERE	czocd.oczdi_id = oczdi.oczdi_id
			      	ORDER BY czoc.dt_create DESC
			      ) oa_czoc
	ORDER BY
		puc.packing_dt