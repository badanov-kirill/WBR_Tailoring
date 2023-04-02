
CREATE PROCEDURE [Products].[ProdArticleNomenclatureTS_GetByID]
@pants_id INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	INSERT INTO Synchro.ProductsForEAN
		(
			pants_id,
			fabricator_id
		)
	SELECT	pants.pants_id, f.fabricator_id
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			LEFT JOIN	Synchro.ProductsForEAN pfe
				ON	pfe.pants_id = pants.pants_id
			CROSS JOIN Settings.Fabricators f
	WHERE	pants.pants_id = @pants_id
			AND	pfe.pants_id IS NULL
			AND f.activ = 1; 
	
	SELECT	pants.pants_id,
			ts.ts_name,
			b.brand_name,
			sj.subject_name,
			pa.sa + pan.sa     sa,
			ISNULL(c.color_name, 'безцветное') color_name,
			e.ean              barcode
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
				ON	panc.pan_id = pan.pan_id
				AND	panc.is_main = 1   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
	WHERE	pants.pants_id = @pants_id