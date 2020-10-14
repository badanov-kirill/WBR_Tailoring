CREATE PROCEDURE [Planing].[SketchPrePlanEquipment_DayInfo]
	@dt DATE,
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	v_eq.office_id,
			v_eq.equipment_id,
			v_eq.cnt_equip cnt_equip,
			ISNULL(v_eq.equipment_second, 0) - ISNULL(vj.job_second, 0) equipment_time
	FROM	(SELECT	zor.office_id,
	    	 		we.equipment_id,
	    	 		COUNT(we.we_id) cnt_equip,
	    	 		SUM(we.work_hour) * 3600 equipment_second
	    	 FROM	Manufactory.WorkshopEquipment we   
	    	 		INNER JOIN	Warehouse.ZoneOfResponse zor
	    	 			ON	zor.zor_id = we.zor_id
	    	 GROUP BY
	    	 	zor.office_id,
	    	 	we.equipment_id)v_eq   
			LEFT JOIN	(SELECT	SUM(spptsw.work_time) job_second,
			    	    	 		spptsw.office_id,
			    	    	 		sppts.equipment_id
			    	    	 FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			    	    	 		INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			    	    	 			ON	sppts.sppts_id = spptsw.sppts_id   
			    	    	 		INNER JOIN	Planing.SketchPrePlan spp
			    	    	 			ON	spp.spp_id = sppts.spp_id
			    	    	 WHERE	spptsw.work_dt = @dt
			    	    			AND	(spp.plan_dt > @finish_dt OR spp.plan_dt < @start_dt)
			    	    	 GROUP BY
			    	    	 	spptsw.office_id,
			    	    	 	sppts.equipment_id)vj
				ON	v_eq.office_id = vj.office_id
				AND	v_eq.equipment_id = vj.equipment_id
	WHERE	ISNULL(v_eq.equipment_second, 0) > ISNULL(vj.job_second, 0)
		