CREATE PROCEDURE [Ozon].[Attributes_GetByCategory]
	@category_id BIGINT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	a.attribute_id,
			a.attribute_name,
			a.attribute_descr,
			ca.is_required,
			dt.data_type_name,
			a.is_collection
	FROM	Ozon.CategoriesAttributes ca   
			INNER JOIN	Ozon.Attributes a
				ON	a.attribute_id = ca.attribute_id   
			INNER JOIN	dbo.DataTypes dt
				ON	dt.data_type_id = a.data_type_id
	WHERE	ca.category_id = @category_id
	ORDER BY a.attribute_id
	