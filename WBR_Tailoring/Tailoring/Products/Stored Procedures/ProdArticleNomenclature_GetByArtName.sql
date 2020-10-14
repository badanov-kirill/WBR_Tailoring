CREATE PROCEDURE [Products].[ProdArticleNomenclature_GetByArtName]
	@art_name VARCHAR(100)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pa.sa + pan.sa sa,
			an.art_name,
			pan.nm_id,
			pan.pan_id
	FROM	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	an.art_name LIKE @art_name + '%'  