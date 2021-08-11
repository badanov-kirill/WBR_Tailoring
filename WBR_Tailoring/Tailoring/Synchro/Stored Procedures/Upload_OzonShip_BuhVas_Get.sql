CREATE PROCEDURE [Synchro].[Upload_OzonShip_BuhVas_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @t TABLE (sfp_id INT, dt DATETIME, rv_bigint BIGINT)
	
	INSERT INTO @t
		(
			sfp_id,
			dt,
			rv_bigint
		)
	SELECT	uosbv.sfp_id,
			CAST(uosbv.dt AS DATETIME)     dt,
			CAST(uosbv.rv AS BIGINT)       rv_bigint
	FROM	Synchro.Upload_OzonShip_BuhVas uosbv
	
	SELECT	t.sfp_id,
			t.dt,
			t.rv_bigint,
			dbo.bin2uid(s.buh_uid)      supplier_uid,
			dbo.bin2uid(oa.buh_uid)     contract_uid
	FROM	@t t   
			INNER JOIN	Logistics.ShipmentFinishedProducts sfp
				ON	sfp.sfp_id = t.sfp_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sfp.supplier_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sc.buh_uid
			      	FROM	Suppliers.SupplierContract sc
			      	WHERE	sc.supplier_id = s.supplier_id
			      	ORDER BY
			      		CASE 
			      		     WHEN sc.is_default = 1 THEN 0
			      		     ELSE sc.suppliercontract_id
			      		END
			      )                     oa
	
	SELECT	t.sfp_id,
			pan.whprice           price,
			pbd.barcode           item_code,
			pa.sa + pan.sa        sa,
			ts.ts_name,
			b.brand_name,
			e.ean,
			a.ozon_fbo_id,
			a.price_with_vat      ozon_price_with_vat,
			COUNT(pbd.pbd_id)     quantity,
			20 nds
	FROM	@t t   
			INNER JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.sfp_id = t.sfp_id   
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
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id   
			LEFT JOIN	Ozon.Articles a
				ON	a.pants_id = pants.pants_id
	GROUP BY
		t.sfp_id,
		pan.whprice,
		pbd.barcode,
		pa.sa + pan.sa,
		ts.ts_name,
		b.brand_name,
		e.ean,
		a.ozon_fbo_id,
		a.price_with_vat