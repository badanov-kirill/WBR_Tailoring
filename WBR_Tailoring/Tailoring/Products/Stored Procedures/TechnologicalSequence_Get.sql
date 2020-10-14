CREATE PROCEDURE [Products].[TechnologicalSequence_Get]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.operation_range,
			ts.ct_id,
			ct.ct_name,
			ts.ta_id,
			ta.ta_name ta,
			ts.element_id,
			e.element_name element,
			ts.equipment_id,
			eq.equipment_name equipment,
			ts.dr_id,
			ts.dc_id,
			ts.operation_value,
			ts.discharge_id,
			ts.rotaiting,
			ts.dc_coefficient,
			cd.comment,
			ts.operation_time
	FROM	Products.TechnologicalSequence ts 
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = ts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = ts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = ts.equipment_id
			INNER JOIN Technology.CommentDict cd
				ON	cd.comment_id = ts.comment_id
	WHERE	ts.sketch_id = @sketch_id
	ORDER BY ts.operation_range