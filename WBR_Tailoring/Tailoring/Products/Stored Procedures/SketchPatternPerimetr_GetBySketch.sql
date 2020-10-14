CREATE PROCEDURE [Products].[SketchPatternPerimetr_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spp.spp_id,
			spp.ts_id,
			ts.ts_name,
			spp.psn_id,
			psn.psn_name,
			spp.perimetr,
			CAST(spp.dt AS DATETIME) dt,
			spp.employee_id
	FROM	Products.SketchPatternPerimetr spp   
			INNER JOIN	Products.PatternSizeName psn
				ON	psn.psn_id = spp.psn_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spp.ts_id
	WHERE spp.sketch_id = @sketch_id
