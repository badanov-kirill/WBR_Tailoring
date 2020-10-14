CREATE PROCEDURE [Products].[Season_Get]
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.season_id,
			s.season_name
	FROM	Products.Season s
	WHERE	@is_deleted IS NULL
			OR	s.isdeleted = @is_deleted
