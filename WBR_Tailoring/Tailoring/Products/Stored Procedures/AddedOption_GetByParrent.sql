CREATE PROCEDURE [Products].[AddedOption_GetByParrent]
	@ao_id_parent INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ao.ao_id,
			ao.ao_name
	FROM	Products.AddedOption ao
	WHERE	ao.ao_id_parent = @ao_id_parent