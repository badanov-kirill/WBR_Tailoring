CREATE PROCEDURE [Products].[ProdArticleNomenclature_GetByNM]
	@nm_id INT
AS

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pan.pan_id,
			pa.sa + pan.sa sa,
			an.art_name,
			pan.nm_id
	FROM	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	pan.nm_id = @nm_id