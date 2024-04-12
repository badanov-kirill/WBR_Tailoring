CREATE PROCEDURE [Logistics].[PlanShipmentFinishedProductsPackingBox_GetDetail_v2]
@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ISNULL(s.imt_name, sj.subject_name_sf) + ', ' + pa.sa + pan.sa + ', ' + ts.ts_name item_name,
			COUNT(pbd.pbd_id)     quantity,
			'796'                 okei_id,
			'шт'                  okei_name,
			pan.whprice           price,
			20                    nds,
			'Россия'              country_name,
			643                   country_id,
			''                    gtd_cod,
			pbd.barcode			  item_code,
			pa.sa + pan.sa        sa,
			ts.ts_name,
			t.tnved_cod,
			pa.sa                 sa_imt,
			pan.sa                sa_nm,
			b.brand_name,
			e.ean,
			sj.subject_name subject_name,
			a.art ozon_art,
			a.ozon_fbo_id,
			a.price_with_vat ozon_price_with_vat
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
			LEFT JOIN Manufactory.EANCode e
				ON e.pants_id = pants.pants_id 
			LEFT JOIN Ozon.Articles a
				ON a.pants_id = pants.pants_id
			OUTER APPLY (
			      	SELECT	TOP(1) c.consist_type_id
			      	FROM	Products.ProdArticleConsist pac   
			      			INNER JOIN	Products.Consist c
			      				ON	c.consist_id = pac.consist_id
			      	WHERE	pac.pa_id = pa.pa_id
			      	ORDER BY
			      		pac.percnt DESC
			      ) oa_ct     
			LEFT JOIN	Products.TNVED_Settigs tnvds   
			LEFT JOIN	Products.TNVED t
				ON	t.tnved_id = tnvds.tnved_id
				ON	tnvds.subject_id = s.subject_id
				AND	tnvds.ct_id = s.ct_id
				AND	tnvds.consist_type_id = oa_ct.consist_type_id
	WHERE	psfppb.sfp_id = @sfp_id
	GROUP BY
		ISNULL(s.imt_name, sj.subject_name_sf),
		sj.subject_name,
		pa.sa,
		pan.sa,
		ts.ts_name,
		pan.whprice,
		pbd.barcode,
		ts.ts_name,
		t.tnved_cod,
		b.brand_name,
		e.ean,
		a.art,
		a.ozon_fbo_id,
		a.price_with_vat
	ORDER BY
		b.brand_name,
		pa.sa,
		pan.sa,
		ts.ts_name
	
	
	SELECT	pbd.barcode item_code,
			COUNT(1) cnt,
			wtb.box_name, 
			psfppb.packing_box_id packing_box_id,
			pa.sa + pan.sa sa,
			ts.ts_name,
			an.art_name,
			MAX(CASE WHEN pucczi.product_unic_code IS NOT NULL THEN 1 ELSE 0 END) have_cz
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.packing_box_id = psfppb.packing_box_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pbd.product_unic_code   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
			INNER JOIN Products.ProdArticle pa
			INNER JOIN Products.Sketch s
			INNER JOIN Products.ArtName an
				ON an.art_name_id = s.art_name_id
				ON s.sketch_id = pa.sketch_id
				ON pa.pa_id = pan.pa_id
				ON	pan.pan_id = pants.pan_id
				ON	pants.pants_id = puc.pants_id
			LEFT JOIN Products.TechSize ts
				ON ts.ts_id = pants.ts_id
			LEFT JOIN Wildberries.WB_TransferBox wtb 
				ON psfppb.packing_box_id = wtb.packing_box_id
			LEFT JOIN Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON pucczi.product_unic_code = puc.product_unic_code 
	WHERE	psfppb.sfp_id = @sfp_id
	GROUP BY
		pbd.barcode,
		wtb.box_name,
		psfppb.packing_box_id,
		pa.sa,
		pan.sa,
		ts.ts_name,
		an.art_name
	ORDER BY
		wtb.box_name,
		psfppb.packing_box_id,
		pbd.barcode
		
	SELECT	pa.sa + pan.sa     sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			e.ean,
			oczdi.gtin01,
			oczdi.serial21,
			oczdi.intrnal91,
			oczdi.intrnal92,
			oczdi.oczdi_id
	FROM	Logistics.ShipmentFinishedProductsChestnyZnak sfpcz   
			INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
				ON	oczdi.oczdi_id = sfpcz.oczdi_id   
			INNER JOIN	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
				ON	pucczi.oczdi_id = oczdi.oczdi_id   
			INNER JOIN Manufactory.OrderChestnyZnakDetail AS oczd
				ON oczd.oczd_id = oczdi.oczd_id
			INNER JOIN Planing.SketchPlanColorVariantTS AS spcvt
				ON spcvt.spcvts_id = oczd.spcvts_id
			INNER JOIN Planing.SketchPlanColorVariant AS spcv
				ON spcv.spcv_id = spcvt.spcv_id
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pucczi.product_unic_code   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = puc.pants_id  AND e.fabricator_id = spcv.sew_fabricator_id 
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id
	WHERE	sfpcz.sfp_id = @sfp_id
	  