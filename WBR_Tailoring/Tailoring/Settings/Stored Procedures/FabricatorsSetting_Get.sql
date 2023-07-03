--exec Settings.FabricatorsSetting_Get null, 1

CREATE PROCEDURE [Settings].[FabricatorsSetting_Get]

	@fabricator_id INT = NULL,
	@fabricator_activ INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	f.fabricator_id,
			f.fabricator_name,
			f.activ,
			f.taxation,
			f.token 
	FROM	[Settings].Fabricators f
	WHERE	(@fabricator_id IS NULL
			OR	f.fabricator_id = @fabricator_id)
			AND (@fabricator_activ IS NULL
			OR	f.activ = @fabricator_activ)