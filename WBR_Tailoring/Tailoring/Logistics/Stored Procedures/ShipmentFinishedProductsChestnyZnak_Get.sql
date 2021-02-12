CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsChestnyZnak_Get]
	@sfp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pa.sa + pan.sa     sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			e.ean              barcode,
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
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = pucczi.product_unic_code   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = puc.pants_id   
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