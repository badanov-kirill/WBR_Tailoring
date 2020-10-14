CREATE PROCEDURE [Planing].[SketchPrePlan_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spp.spp_id,
			spps.spps_name,
			spp.season_model_year,
			sl.season_local_name,
			CAST(spp.plan_dt AS DATETIME) plan_dt,
			spp.plan_qty,
			spp.cv_qty
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Planing.SketchPrePlanStatus spps
				ON	spps.spps_id = spp.spps_id   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = spp.season_local_id
	WHERE spp.sketch_id = @sketch_id