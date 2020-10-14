CREATE PROCEDURE [Logistics].[TransferBoxDetail_Get]
	@transfer_box_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brand_name,
			sj.subject_name,
			an.art_name,
			pa.sa + pan.sa sa,
			ts.ts_name,
			tbd.product_unic_code
	FROM	Logistics.TransferBoxDetail tbd   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.product_unic_code = tbd.product_unic_code   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = puc.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	tbd.transfer_box_id = @transfer_box_id