CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_GetBySPCV]
	@spcv_id INT
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
			cd.comment,
			ts.operation_time,
			ts.sts_id,
			stsjc.cost_per_hour * ts.operation_time/ 3600 operation_cost
	FROM	Manufactory.SPCV_TechnologicalSequence ts  
			INNER JOIN Planing.SketchPlanColorVariant spcv
				ON spcv.spcv_id = ts.spcv_id 
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = ts.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = ts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = ts.element_id   
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = ts.equipment_id
			INNER JOIN Technology.CommentDict cd
				ON cd.comment_id = ts.comment_id
			LEFT JOIN Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
				ON stsjc.discharge_id = ts.discharge_id
				AND spcv.sew_office_id = stsjc.office_id
	WHERE	ts.spcv_id = @spcv_id
	ORDER BY
		ts.operation_range		