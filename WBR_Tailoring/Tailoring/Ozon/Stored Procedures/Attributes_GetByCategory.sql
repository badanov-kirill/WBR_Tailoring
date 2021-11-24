CREATE PROCEDURE [Ozon].[Attributes_GetByCategory]
	@category_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	a.attribute_id,
			a.attribute_name,
			a.attribute_descr,
			ca.is_required,
			dt.data_type_name
	FROM	Ozon.CategoriesAttributes ca   
			INNER JOIN	Ozon.Attributes a
				ON	a.attribute_id = ca.attribute_id   
			INNER JOIN	dbo.DataTypes dt
				ON	dt.data_type_id = a.data_type_id
	WHERE	ca.category_id = @category_id
	
	SELECT	ca.attribute_id,
			av.av_id,
			av.av_value
	FROM	Ozon.CategoriesAttributes ca   
			INNER JOIN	Ozon.CategoriesAttributeValues cav
				ON	cav.category_id = ca.category_id
				AND	cav.attribute_id = ca.attribute_id   
			INNER JOIN	Ozon.AttributeValues av
				ON	av.av_id = cav.av_id
	WHERE	ca.category_id = @category_id