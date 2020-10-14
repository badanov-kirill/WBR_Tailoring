CREATE PROCEDURE [Products].[SubjectBrandTPGroup_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sbt.subject_id,
			s.subject_name,
			sbt.brand_id,
			b.brand_name,
			sbt.kind_id,
			k.kind_name,
			sbt.tpgroup_id,
			t.tpgroup_name
	FROM	Products.SubjectBrandTPGroup sbt   
			INNER JOIN	Products.[Subject] s
				ON	s.subject_id = sbt.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = sbt.brand_id
			INNER JOIN Products.Kind k
				ON sbt.kind_id = k.kind_id   
			INNER JOIN	Products.TPGroup t
				ON	t.tpgroup_id = sbt.tpgroup_id
	ORDER BY
		s.subject_name,
		b.brand_name
	