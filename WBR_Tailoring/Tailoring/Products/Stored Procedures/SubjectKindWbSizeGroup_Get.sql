CREATE PROCEDURE [Products].[SubjectKindWbSizeGroup_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	skw.subject_id,
			s.subject_name,
			skw.kind_id,
			k.kind_name,
			skw.wb_size_group_id,
			wsg.wb_size_group_description
	FROM	Products.SubjectKindWbSizeGroup skw   
			INNER JOIN	Products.[Subject] s
				ON	s.subject_id = skw.subject_id   
			INNER JOIN	Products.Kind k
				ON	k.kind_id = skw.kind_id   
			INNER JOIN	Products.WbSizeGroup wsg
				ON	wsg.wb_size_group_id = skw.wb_size_group_id
	ORDER BY
		s.subject_name,
		k.kind_name