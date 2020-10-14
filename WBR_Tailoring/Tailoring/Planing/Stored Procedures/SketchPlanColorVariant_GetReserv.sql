CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetReserv]
	@spcv_id INT,
	@is_cloth BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smr.shkrm_id,
			rmt.rmt_name,
			cc.color_name,
			smai.frame_width,
			SUM(smr.quantity)     quantity,
			o.symbol              okei_symbol,
			smai.stor_unit_residues_qty
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			LEFT JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = spcvc.completing_id
	WHERE	spcvc.spcv_id = @spcv_id
			AND	(@is_cloth IS NULL OR (@is_cloth = 1 AND cic.completing_id IS NOT NULL) OR (@is_cloth = 0 AND cic.completing_id IS NULL))
	GROUP BY
		smr.shkrm_id,
		rmt.rmt_name,
		cc.color_name,
		smai.frame_width,
		o.symbol,
		smai.stor_unit_residues_qty