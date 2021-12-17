CREATE PROCEDURE [Ozon].[Attributes_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @category_id BIGINT 
	
	SELECT	@category_id = sc.category_id
	FROM	Products.Sketch s   
			LEFT JOIN	Ozon.SubjectsCategories sc
				ON	sc.subject_id = s.subject_id
	WHERE	s.sketch_id = @sketch_id
	
	IF @category_id IS NULL
	BEGIN
	    RAISERROR('Не установлено соответствие предмета категории ОЗОН', 16, 1)
	    RETURN
	END
	
	SELECT	a.attribute_id,
			a.attribute_name,
			a.attribute_descr,
			CASE 
			     WHEN ca.is_required = 1 OR a.is_required_us = 1 THEN 1
			     ELSE 0
			END is_required,
			dt.data_type_name,
			a.is_collection
	FROM	Ozon.CategoriesAttributes ca   
			INNER JOIN	Ozon.Attributes a
				ON	a.attribute_id = ca.attribute_id   
			INNER JOIN	dbo.DataTypes dt
				ON	dt.data_type_id = a.data_type_id
	WHERE	ca.category_id = @category_id
			AND	a.is_used = 1
	
	SELECT	ca.attribute_id,
			av.av_id,
			av.av_value
	FROM	Ozon.CategoriesAttributes ca   
			INNER JOIN	Ozon.Attributes a
				ON	a.attribute_id = ca.attribute_id   
			INNER JOIN	Ozon.CategoriesAttributeValues cav
				ON	cav.category_id = ca.category_id
				AND	cav.attribute_id = ca.attribute_id   
			INNER JOIN	Ozon.AttributeValues av
				ON	av.av_id = cav.av_id
	WHERE	ca.category_id = @category_id
			AND	av.is_used = 1
			AND	a.is_used = 1