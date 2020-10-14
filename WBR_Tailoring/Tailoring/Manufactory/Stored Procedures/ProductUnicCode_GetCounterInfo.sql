CREATE PROCEDURE [Manufactory].[ProductUnicCode_GetCounterInfo]
@product_unic_code INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_name,
			spcvtsc.cutting_qty,
			spcvtsc.cut_write_off,
			spcvtsc.write_off,
			spcvtsc.packaging
	FROM	Manufactory.ProductUnicCode puc   
			INNER JOIN	Manufactory.Cutting c
				ON	c.cutting_id = puc.cutting_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt2
				ON	spcvt2.spcv_id = spcvt.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariantTSCounter spcvtsc
				ON	spcvtsc.spcvts_id = spcvt2.spcvts_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt2.ts_id
	WHERE	puc.product_unic_code = @product_unic_code
	ORDER BY
		ts.visible_queue,
		ts.ts_name