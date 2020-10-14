CREATE PROCEDURE [Planing].[PreCostReserv_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			o.symbol                 okei_symbol,
			cc.color_name,
			cr.qty                   qty,
			a.art_name,
			cr.pre_cost,
			cr.pre_cost / cr.qty     pre_price
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.PreCostReserv cr
				ON	cr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = cr.okei_id
	WHERE	spcvc.spcv_id = @spcv_id