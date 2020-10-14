CREATE PROCEDURE [Planing].[PlantLoadingPlanEquipment_DayInfo]
	@dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v_eq.office_id,
			v_eq.equipment_id,
			v_eq.cnt_equip,
			ISNULL(v_eq.work_hour, 0) - ISNULL(vj.job_second, 0) equipment_time
	FROM	(SELECT	zor.office_id,
	    	 		we.equipment_id,
	    	 		COUNT(we.we_id) cnt_equip,
	    	 		SUM(we.work_hour) * 3600 work_hour
	    	 FROM	Manufactory.WorkshopEquipment we   
	    	 		INNER JOIN	Warehouse.ZoneOfResponse zor
	    	 			ON	zor.zor_id = we.zor_id
	    	 GROUP BY
	    	 	zor.office_id,
	    	 	we.equipment_id)v_eq   
			LEFT JOIN	(SELECT	SUM(plptsw.work_time) job_second,
			    	    	 		plptsw.office_id,
			    	    	 		plpts.equipment_id
			    	    	 FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw   
			    	    	 		INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
			    	    	 			ON	plpts.plpts_id = plptsw.plpts_id   
			    	    	 		INNER JOIN	Planing.PlantLoadingPlan plp
			    	    	 			ON	plp.spcv_id = plpts.spcv_id
			    	    	 WHERE	plptsw.work_dt = @dt
			    	    	 GROUP BY
			    	    	 	plptsw.office_id,
			    	    	 	plpts.equipment_id)vj
				ON	v_eq.office_id = vj.office_id
				AND	v_eq.equipment_id = vj.equipment_id
	WHERE	ISNULL(v_eq.work_hour, 0) > ISNULL(vj.job_second, 0)
	