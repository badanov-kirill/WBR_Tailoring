CREATE PROCEDURE [Products].[Style_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.style_id,
			s.style_name
	FROM	Products.Style s
	WHERE	s.is_deleted = 0