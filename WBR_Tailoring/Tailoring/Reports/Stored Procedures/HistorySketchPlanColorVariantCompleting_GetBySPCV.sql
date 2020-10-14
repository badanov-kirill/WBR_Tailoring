CREATE PROCEDURE [Reports].[HistorySketchPlanColorVariantCompleting_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcvc.log_id,
			spcvc.spcvc_id,
			spcvc.completing_id,
			c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			spcvc.rmt_id,
			rmt.rmt_name,
			spcvc.comment,
			spcvc.frame_width,
			spcvc.okei_id,
			spcvc.consumption,
			o.symbol,
			spcvc.color_id,
			cc.color_name,
			CASE 
			     WHEN cic.completing_id IS NULL THEN 0
			     ELSE 1
			END is_cloth,
			spcvc.cs_id,
			cs.cs_name,
			sp.proc_name,
			CAST(spcvc.dt AS DATETIME) dt,
			spcvc.employee_id
	FROM	History.SketchPlanColorVariantCompleting spcvc   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = spcvc.color_id   
			LEFT JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = c.completing_id   
			LEFT JOIN	Planing.CompletingStatus cs
				ON	spcvc.cs_id = cs.cs_id   
			INNER JOIN	History.StoredProcedure sp
				ON	sp.proc_id = spcvc.proc_id
	WHERE	spcvc.spcv_id = @spcv_id
	ORDER BY
		c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)), 
		spcvc.log_id