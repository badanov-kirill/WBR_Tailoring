
CREATE PROCEDURE [Settings].[FabricatorsSetting_Get]

	@fabricator_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	f.fabricator_id,
			f.fabricator_name
	FROM	[Settings].Fabricators f
	WHERE	@fabricator_id IS NULL
			OR	f.fabricator_id = @fabricator_id