CREATE PROCEDURE [Technology].[TechActionRationing_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tar.ct_id,
			tar.ta_id,
			tar.element_id,
			tar.equipment_id,
			tar.dr_id,
			tar.rotaiting
	FROM	Technology.TechActionRationing tar