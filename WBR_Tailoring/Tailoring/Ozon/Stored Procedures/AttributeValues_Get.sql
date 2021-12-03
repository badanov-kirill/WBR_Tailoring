CREATE PROCEDURE [Ozon].[AttributeValues_Get]
	@category_id BIGINT,
	@attribute_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	av.av_id,
			av.av_value,
			av.is_used
	FROM	Ozon.AttributeValues av   
			INNER JOIN	Ozon.CategoriesAttributeValues cav
				ON	cav.av_id = av.av_id
	WHERE	cav.category_id = @category_id
			AND	cav.attribute_id = @attribute_id
	ORDER BY av.is_used DESC, av.av_value