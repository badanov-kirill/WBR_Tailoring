CREATE PROCEDURE [Technology].[TechnologicalPatternSequence_Get]
	@tp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.operation_range,
			ts.ct_id,
			ct.ct_name,
			ts.ta_id,
			ta.ta_name            ta,
			ts.element_id,
			e.element_name        element,
			ts.equipment_id,
			eq.equipment_name     equipment,
			ts.dr_id,
			ts.dc_id,
			ts.operation_value,
			ts.discharge_id,
			ts.rotaiting,
			ts.dc_coefficient,
			ts.comment,
			ts.operation_time
	FROM	Technology.TechnologicalPatternSequence ts   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = ts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = ts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = ts.equipment_id
	WHERE	ts.tp_id = @tp_id
	ORDER BY ts.operation_range