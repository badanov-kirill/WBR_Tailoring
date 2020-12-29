CREATE PROCEDURE [Logistics].[FindPackingBoxByBarcode_v2]
	@barcode VARCHAR(13) = NULL,
	@art_name VARCHAR(50) = NULL,
	@pants_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @barcode IS NULL
	   AND @art_name IS NULL
	   AND @pants_id IS NULL
	BEGIN
	    RAISERROR('не передано ни одного отбра', 16, 1)
	    RETURN
	END
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa                   sa_imt,
			pan.sa                  sa_nm,
			ts.ts_name,
			k.kind_name,
			'PGBX' + CAST(pbd.packing_box_id AS VARCHAR(10)) + '=' + RIGHT(
				CAST(SUBSTRING(hashbytes('MD5', CAST(pbd.packing_box_id AS VARCHAR(10))), DATALENGTH(hashbytes('MD5', CAST(pbd.packing_box_id AS VARCHAR(10)))) -1, 2) AS INT),
				3
			)                       packing_box,
			COUNT(puc.pants_id)     cnt,
			os.office_name,
			sp.place_name,
			CASE 
			     WHEN psfppb.packing_box_id IS NOT NULL THEN 1
			     ELSE 0
			END                     is_plan_shipping
	FROM	Logistics.PackingBoxDetail pbd   
			INNER JOIN	Manufactory.ProductUnicCode puc
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
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pbd.packing_box_id   
			INNER JOIN	Warehouse.PackingBoxOnPlace pbop
				ON	pbop.packing_box_id = pbd.packing_box_id   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
	WHERE	(@barcode IS NULL OR pbd.barcode = @barcode)
			AND	(@art_name IS NULL OR (an.art_name = @art_name AND psfppb.packing_box_id IS NULL))
			AND (@pants_id IS NULL OR pants.pants_id = @pants_id)
	GROUP BY
		b.brand_name,
		sj.subject_name,
		an.art_name,
		pa.sa,
		pan.sa,
		ts.ts_name,
		k.kind_name,
		pbd.packing_box_id,
		os.office_name,
		sp.place_name,
		CASE 
		     WHEN psfppb.packing_box_id IS NOT NULL THEN 1
		     ELSE 0
		END       