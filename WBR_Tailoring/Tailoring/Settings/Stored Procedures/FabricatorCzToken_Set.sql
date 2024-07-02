CREATE PROCEDURE [Settings].[FabricatorCzToken_Set]
	@fabricator_id INT, 
	@token VARCHAR(3000)
AS
	SET NOCOUNT ON
	
	UPDATE Settings.Fabricators
	SET    CZ_Token          = @token, CZ_TokenDT = GETDATE()
	WHERE  fabricator_id     = @fabricator_id