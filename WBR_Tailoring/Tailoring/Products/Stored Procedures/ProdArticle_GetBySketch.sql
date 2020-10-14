CREATE PROCEDURE [Products].[ProdArticle_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pa.pa_id,
			pa.brand_id,
			b.brand_name,
			pa.season_id,
			s.season_name,
			pa.style_id,
			s2.style_name,
			pa.model_number
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.Season s
				ON	s.season_id = pa.season_id   
			LEFT JOIN	Products.Style s2
				ON	s2.style_id = pa.style_id
	WHERE	pa.sketch_id = @sketch_id
			AND	pa.is_deleted = 0
	ORDER BY
		pa.pa_id ASC
     	
     	