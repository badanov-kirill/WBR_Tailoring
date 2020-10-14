CREATE PROCEDURE [Manufactory].[LayoutCompleting_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sc.completing_id,
			c.completing_name,
			sc.completing_number,
			rmt.rmt_name
	FROM	Products.SketchCompleting sc   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = sc.completing_id   
			INNER JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = c.completing_id
			LEFT JOIN Material.RawMaterialType rmt
				ON rmt.rmt_id = sc.base_rmt_id
	WHERE	sc.sketch_id = @sketch_id
			AND sc.is_deleted = 0
	ORDER BY
		c.completing_id,
		sc.completing_number