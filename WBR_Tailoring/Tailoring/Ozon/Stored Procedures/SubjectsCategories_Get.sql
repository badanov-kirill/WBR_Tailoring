CREATE PROCEDURE [Ozon].[SubjectsCategories_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.subject_id,
			s.subject_name,
			c.category_id,
			c.category_name
	FROM	Products.[Subject] s   
			LEFT JOIN	Ozon.SubjectsCategories sc
				ON	sc.subject_id = s.subject_id   
			LEFT JOIN	Ozon.Categories c
				ON	c.category_id = sc.category_id