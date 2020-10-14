CREATE PROCEDURE [Material].[Consists_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT c.consist_id,
	       c.consist_name,
	       c.consist_name_eng
	FROM   Material.Consists c
	WHERE  c.isdeleted = 0
	ORDER BY c.consist_name