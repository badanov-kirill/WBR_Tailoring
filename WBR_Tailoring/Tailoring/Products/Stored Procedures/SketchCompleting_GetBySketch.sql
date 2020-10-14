CREATE PROCEDURE [Products].[SketchCompleting_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sc.completing_id,
			c.completing_name,
			sc.completing_number,
			sc.frame_width,
			sc.okei_id,
			o.symbol           okei_symbol,
			sc.consumption,
			sc.comment,
			oa.x               rmts,
			rmt.rmt_name       base_rmt_name,
			sc.base_rmt_id     base_rmt_id
	FROM	Products.SketchCompleting sc   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = sc.okei_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = sc.base_rmt_id   
			OUTER APPLY (
			      	SELECT	scrm.rmt_id '@id',
			      			rmt.rmt_name '@name',
			      			CASE 
			      			     WHEN scrm.rmt_id = sc.base_rmt_id THEN 1
			      			     ELSE 0
			      			END '@m'
			      	FROM	Products.SketchCompletingRawMaterial scrm   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = scrm.rmt_id
			      	WHERE	scrm.sc_id = sc.sc_id
			      	FOR XML	PATH('rmt'), ROOT('rmts')
			      ) oa(x)
	WHERE	sc.is_deleted = 0
			AND	sc.sketch_id = @sketch_id
	ORDER BY c.visible_queue, sc.completing_id