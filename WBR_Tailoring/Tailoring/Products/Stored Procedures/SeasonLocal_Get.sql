CREATE PROCEDURE [Products].[SeasonLocal_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sl.season_local_id,
			sl.season_local_name
	FROM	Products.SeasonLocal sl
	WHERE	sl.is_deleted = 0
