CREATE PROCEDURE [Planing].[SketchPrePlan_TechnologicalSequenceWork_Get]
	@start_dt DATE,
	@finish_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(spptsw.work_dt AS DATETIME) work_dt,
			spptsw.work_time,
			sppts.operation_range,
			sppts.operation_time,
			e.equipment_name,
			CAST(spp.plan_dt AS DATETIME) plan_dt,
			spp.plan_qty,
			spp.cv_qty,
			sj.subject_name,
			b.brand_name,
			an.art_name,
			s.sa,
			os.office_name
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
				ON	sppts.spp_id = spp.spp_id   
			INNER JOIN	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw
				ON	spptsw.sppts_id = sppts.sppts_id   
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
			INNER JOIN	Technology.Equipment e
				ON	e.equipment_id = sppts.equipment_id
	WHERE	spptsw.work_dt >= @start_dt
			AND	spptsw.work_dt <= @finish_dt