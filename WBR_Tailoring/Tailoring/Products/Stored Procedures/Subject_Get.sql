CREATE PROCEDURE [Products].[Subject_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.subject_id,
			s.subject_name,
			s.subject_name_sf
	FROM	Products.[Subject] s
	WHERE	s.isdeleted = 0
