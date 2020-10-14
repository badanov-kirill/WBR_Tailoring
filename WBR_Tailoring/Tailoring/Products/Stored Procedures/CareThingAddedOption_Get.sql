CREATE PROCEDURE [Products].[CareThingAddedOption_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ctao.ao_id,
			ctao.ctg_id,
			ctao.img_name,
			ao.ao_name,
			ao.ao_name_eng
	FROM	Products.CareThingAddedOption ctao   
			INNER JOIN	Products.AddedOption ao
				ON	ao.ao_id = ctao.ao_id