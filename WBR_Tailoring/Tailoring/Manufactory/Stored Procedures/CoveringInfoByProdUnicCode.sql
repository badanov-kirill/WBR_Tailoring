
CREATE PROCEDURE [Manufactory].[CoveringInfoByProdUnicCode]
	@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	INSERT INTO Synchro.ProductsForEAN
		(
			pants_id,
			fabricator_id
		)
		SELECT	 pants.pants_id, f.fabricator_id
		FROM	Manufactory.ProductUnicCode puc   
				INNER JOIN	Manufactory.Cutting c0
					ON	c0.cutting_id = puc.cutting_id   
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt0
					ON	spcvt0.spcvts_id = c0.spcvts_id   
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcvt0.spcv_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = cd.spcv_id   
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcv_id = spcv.spcv_id   
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = spcv.pan_id   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pan_id = pan.pan_id
					AND	pants.ts_id = spcvt.ts_id   
				LEFT JOIN	Manufactory.EANCode e
					ON	e.pants_id = pants.pants_id   
				LEFT JOIN	Synchro.ProductsForEAN se
					ON	se.pants_id = pants.pants_id
				CROSS JOIN Settings.Fabricators f
		WHERE	puc.product_unic_code = @product_unic_code
				AND	e.pants_id IS NULL
				AND	se.pants_id IS NULL; 
	
	
	SELECT	pa.sa + pan.sa     sa,
			an.art_name,
			pan.nm_id,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ts.ts_name,
			e.ean,
			spcvt2.packaging,
			oaocz.cnt_ordered_cz,
			oaucz.cnt_load_cz, 
			oaucz.cnt_used_cz,
			cd.covering_id,
			spcvt.spcvts_id
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c0
				ON	c0.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt0
				ON	spcvt0.spcvts_id = c0.spcvts_id   
			INNER JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcvt0.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt0.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = spcv.spcv_id   
			LEFT JOIN Planing.SketchPlanColorVariantTSCounter spcvt2
				ON spcvt2.spcvts_id = spcvt.spcvts_id
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
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
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id
				AND	pants.ts_id = spcvt.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id   
			OUTER APPLY (
			      	SELECT	SUM(oczd.cnt) cnt_ordered_cz
			      	FROM	Manufactory.OrderChestnyZnakDetail oczd
			      	WHERE	oczd.spcvts_id = spcvt.spcvts_id
			      ) oaocz
			OUTER APPLY (
	      			SELECT	COUNT(1) cnt_load_cz,
	      					SUM(CASE WHEN pucczi.oczdi_id IS NOT NULL THEN 1 ELSE 0 END) cnt_used_cz
	      			FROM	Manufactory.OrderChestnyZnakDetail oczd   
	      					INNER JOIN	Manufactory.OrderChestnyZnakDetailItem oczdi
	      						ON	oczdi.oczd_id = oczd.oczd_id   
	      					LEFT JOIN	Manufactory.ProductUnicCode_ChestnyZnakItem pucczi
	      						ON	pucczi.oczdi_id = oczdi.oczdi_id
	      			WHERE	oczd.spcvts_id = spcvt.spcvts_id
				  )                    oaucz
	WHERE	puc.product_unic_code = @product_unic_code 
		
	