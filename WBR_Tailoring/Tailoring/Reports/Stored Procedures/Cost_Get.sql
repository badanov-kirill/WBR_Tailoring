CREATE PROCEDURE [Reports].[Cost_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pa.sa + pan.sa         sa_name,
			pan.price_ru           price,
			pan.whprice,
			pan.nm_id,
			an.art_name,
			b.brand_name,
			sj.subject_name
	FROM	Products.Sketch s   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.sketch_id = s.sketch_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	pan.whprice IS NOT     NULL

