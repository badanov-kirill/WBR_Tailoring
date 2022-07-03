CREATE PROCEDURE [Reports].[BarcodeCosts]
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
	SELECT	e.ean              barcode,
			pan.nm_id,
			pa.sa + pan.sa     sa,
			ts.ts_name,
			oa.cost_rm,
			oa.cost_work,
			oa.cost_fix,
			oa.cost_add,
			oa.cost_cutting,
			oa.cost_rm_without_nds,
			oa.price_ru
	FROM	Manufactory.EANCode e   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pants_id = e.pants_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			CROSS APPLY (
			      	SELECT	TOP(1) spcvc.cost_rm,
			      			spcvc.cost_work,
			      			spcvc.cost_fix,
			      			spcvc.cost_add,
			      			spcvc.price_ru,
			      			spcvc.cost_cutting,
			      			spcvc.cost_rm_without_nds
			      	FROM	Planing.SketchPlanColorVariantCost spcvc
			      	WHERE	spcvc.pan_id = pan.pan_id
			      	ORDER BY
			      		spcvc.spcv_id
			      )            oa
	UNION
	SELECT	'wbbc' + CAST(pants.pants_id AS VARCHAR(10)) barcode,
			pan.nm_id,
			pa.sa + pan.sa     sa,
			ts.ts_name,
			oa.cost_rm,
			oa.cost_work,
			oa.cost_fix,
			oa.cost_add,
			oa.cost_cutting,
			oa.cost_rm_without_nds,
			oa.price_ru
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			CROSS APPLY (
			      	SELECT	TOP(1) spcvc.cost_rm,
			      			spcvc.cost_work,
			      			spcvc.cost_fix,
			      			spcvc.cost_add,
			      			spcvc.price_ru,
			      			spcvc.cost_cutting,
			      			spcvc.cost_rm_without_nds
			      	FROM	Planing.SketchPlanColorVariantCost spcvc
			      	WHERE	spcvc.pan_id = pan.pan_id
			      	ORDER BY
			      		spcvc.spcv_id
			      )            oa
