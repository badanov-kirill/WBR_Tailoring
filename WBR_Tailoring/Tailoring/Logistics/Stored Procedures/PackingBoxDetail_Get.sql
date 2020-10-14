CREATE PROCEDURE [Logistics].[PackingBoxDetail_Get]
	@packing_box_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
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
			COUNT(pbd.pbd_id)     cnt,
			CAST(MAX(spcv.deadline_package_dt) AS DATETIME) deadline_package_dt,
			puc.pants_id,
			pbd.barcode
	FROM	Logistics.PackingBoxDetail pbd   
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
			LEFT JOIN	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id
				ON	spcvt.spcvts_id = c.spcvts_id
				ON	c.cutting_id = puc.cutting_id
	WHERE	pbd.packing_box_id = @packing_box_id
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
		pan.price_ru,
		puc.pants_id,
		pbd.barcode