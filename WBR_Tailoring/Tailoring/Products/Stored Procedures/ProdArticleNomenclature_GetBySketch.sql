CREATE PROCEDURE [Products].[ProdArticleNomenclature_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') + pan.sa sa,
			pan.whprice,
			pan.price_ru,
			pan.nm_id,
			pan.pan_id,
			pa.pa_id
	FROM	Products.Sketch s   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.sketch_id = s.sketch_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id
	WHERE	s.sketch_id = @sketch_id
			AND	s.is_deleted = 0
			AND	pa.is_deleted = 0