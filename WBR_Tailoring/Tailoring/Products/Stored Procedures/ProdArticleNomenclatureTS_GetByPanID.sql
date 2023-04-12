CREATE PROCEDURE [Products].[ProdArticleNomenclatureTS_GetByPanID]
@pan_id INT,
@fabricator_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pants.pants_id,
			pants.ts_id,
			ts.ts_name,
			e.ean barcode
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
	WHERE	pants.pan_id = @pan_id
		AND e.fabricator_id = @fabricator_id 
	ORDER BY
		ts.visible_queue,
		ts.ts_name