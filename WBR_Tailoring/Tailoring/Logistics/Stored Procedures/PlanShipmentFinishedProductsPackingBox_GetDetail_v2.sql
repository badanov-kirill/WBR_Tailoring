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
			b.brand_name
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
		pa.sa,
		pan.sa,
		ts.ts_name,
		pan.whprice,
		pbd.barcode,
		ts.ts_name,
		t.tnved_cod,
		b.brand_name
	ORDER BY
		b.brand_name,
		pa.sa,
		pan.sa,
		ts.ts_name
	
	
	SELECT	pbd.barcode item_code,
			COUNT(1) cnt,
			wtb.box_name, 
			psfppb.packing_box_id packing_box_id
	FROM	Logistics.PlanShipmentFinishedProductsPackingBox psfppb   
			INNER JOIN	Logistics.PackingBoxDetail pbd
				ON	pbd.packing_box_id = psfppb.packing_box_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pbd.product_unic_code   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id
				ON	pants.pants_id = puc.pants_id
			LEFT JOIN Wildberries.WB_TransferBox wtb ON psfppb.packing_box_id = wtb.packing_box_id
	WHERE	psfppb.sfp_id = @sfp_id
	GROUP BY
		pbd.barcode,
		wtb.box_name,
		psfppb.packing_box_id
	ORDER BY
		wtb.box_name,
		psfppb.packing_box_id,
		pbd.barcode