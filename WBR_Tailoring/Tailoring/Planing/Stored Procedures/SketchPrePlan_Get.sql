CREATE PROCEDURE [Planing].[SketchPrePlan_Get]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spp.spp_id,
			spp.sketch_id,
			CAST(spp.plan_dt AS DATETIME) plan_dt,
			spp.sew_office_id,
			spp.plan_qty,
			spp.cv_qty,
			sj.subject_name,
			b.brand_name,
			an.art_name,
			s.sa,
			os.office_name,
			ISNULL(oa_t.technology, 0) technology
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = spp.sketch_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = spp.sew_office_id
			OUTER APPLY (
			      	SELECT	TOP(1) 1 technology
			      	FROM	Planing.SketchPrePlan_TechnologicalSequence sppts
			      	WHERE	sppts.spp_id = spp.spp_id
			      ) oa_t
	WHERE	spp.plan_dt >= @start_dt
			AND	spp.plan_dt <= @finish_dt
	ORDER BY
		spp.plan_dt DESC
	
	SELECT	cast(ve.work_dt AS DATETIME) work_dt,
			ve.office_id,
			ve.work_time - ISNULL(vj.job_second, 0) work_time
	FROM	(SELECT	et.work_dt,
	    	 		SUM(et.work_time) * 3600 work_time,
	    	 		es.office_id
	    	 FROM	Planing.EmployeeTable et   
	    	 		INNER JOIN	Settings.EmployeeSetting es
	    	 			ON	es.employee_id = et.work_employee_id
	    	 WHERE	et.work_dt >= @start_dt
	    	 		AND	et.work_dt <= @finish_dt
	    	 GROUP BY
	    	 	et.work_dt,
	    	 	es.office_id)ve   
			LEFT JOIN	(SELECT	spptsw.work_dt,
			    	    	 		SUM(spptsw.work_time) job_second,
			    	    	 		spptsw.office_id
			    	    	 FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			    	    	 		INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			    	    	 			ON	sppts.sppts_id = spptsw.sppts_id   
			    	    	 		INNER JOIN	Planing.SketchPrePlan spp
			    	    	 			ON	spp.spp_id = sppts.spp_id
			    	    	 WHERE	spptsw.work_dt >= @start_dt
			    	    	 		AND	spptsw.work_dt <= @finish_dt
			    	    	 		AND (spp.plan_dt > @finish_dt OR spp.plan_dt < @start_dt)
			    	    	 GROUP BY
			    	    	 	spptsw.work_dt,
			    	    	 	spptsw.office_id)vj
				ON	ve.office_id = vj.office_id
				AND	ve.work_dt = vj.work_dt
	WHERE ve.work_time - ISNULL(vj.job_second, 0) > 0
				
	SELECT	CAST(c.calendar_date AS DATETIME) work_dt,
			v_eq.office_id,
			v_eq.equipment_id,
			v_eq.cnt_equip,
			ISNULL(v_eq.equipment_second, 0) - ISNULL(vj.job_second, 0) equipment_time
	FROM	(SELECT	zor.office_id,
	    	 		we.equipment_id,
	    	 		COUNT(we.we_id) cnt_equip,
	    	 		SUM(we.work_hour * 3600) equipment_second
	    	 FROM	Manufactory.WorkshopEquipment we   
	    	 		INNER JOIN	Warehouse.ZoneOfResponse zor
	    	 			ON	zor.zor_id = we.zor_id
	    	 GROUP BY
	    	 	zor.office_id,
	    	 	we.equipment_id)v_eq   
			CROSS JOIN	RefBook.Calendar c   
			LEFT JOIN	(SELECT	spptsw.work_dt,
			    	    	 		SUM(spptsw.work_time) job_second,
			    	    	 		spptsw.office_id,
			    	    	 		sppts.equipment_id
			    	    	 FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
			    	    	 		INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
			    	    	 			ON	sppts.sppts_id = spptsw.sppts_id   
			    	    	 		INNER JOIN	Planing.SketchPrePlan spp
			    	    	 			ON	spp.spp_id = sppts.spp_id
			    	    	 WHERE	spptsw.work_dt >= @start_dt
			    	    	 		AND	spptsw.work_dt <= @finish_dt
			    	    	 		AND	(spp.plan_dt > @finish_dt OR spp.plan_dt < @start_dt)
			    	    	 GROUP BY
			    	    	 	spptsw.work_dt,
			    	    	 	spptsw.office_id,
			    	    	 	sppts.equipment_id)vj
				ON	v_eq.office_id = vj.office_id
				AND	c.calendar_date = vj.work_dt
				AND	v_eq.equipment_id = vj.equipment_id
	WHERE	c.calendar_date >= @start_dt
			AND	c.calendar_date <= @finish_dt
			AND	ISNULL(v_eq.equipment_second, 0) > ISNULL(vj.job_second, 0)