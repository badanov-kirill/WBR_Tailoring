CREATE PROCEDURE [Technology].[TechActionDCCoefficient_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tad.ct_id,
			tad.ta_id,
			tad.element_id,
			tad.equipment_id,
			tad.dc_id,
			tad.dc_coefficient
	FROM	Technology.TechActionDCCoefficient tad