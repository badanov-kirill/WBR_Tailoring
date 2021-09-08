CREATE PROCEDURE [Products].[SubjectsGS1_GetAll]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sg.subject_gs1_id,
			sg.subject_name
	FROM	Products.SubjectsGS1 sg
	ORDER BY
		sg.subject_gs1_id
