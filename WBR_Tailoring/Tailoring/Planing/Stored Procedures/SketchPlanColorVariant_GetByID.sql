CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetByID]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcvc.spcvc_id,
			spcvc.completing_id,
			c.completing_name,
			spcvc.completing_number,
			spcvc.rmt_id,
			rmt.rmt_name,
			spcvc.comment,
			spcvc.frame_width,
			spcvc.okei_id,
			spcvc.consumption,
			o.symbol,
			spcvc.color_id,
			cc.color_name,
			spcvc.consumption * spcv.qty     qty,
			oar.qty                          reserv_qty,
			CASE 
			     WHEN cic.completing_id IS NULL THEN 0
			     ELSE 1
			END                              is_cloth,
			oa_art.art_name			
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = spcvc.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = spcvc.okei_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = spcvc.color_id   
			LEFT JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = c.completing_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = spcvc.spcvc_id
			      ) oar
			OUTER APPLY (
	      			SELECT	TOP(1) a.art_name
	      			FROM	Warehouse.SHKRawMaterialReserv smr   
	      					INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
	      						ON	smai.shkrm_id = smr.shkrm_id   
	      					INNER JOIN	Material.Article a
	      						ON	a.art_id = smai.art_id
	      			WHERE	smr.spcvc_id = spcvc.spcvc_id
	      			ORDER BY
	      				smai.qty DESC
				  )                                  oa_art
	WHERE	spcvc.spcv_id = @spcv_id
	ORDER BY
		CASE 
		     WHEN cic.completing_id IS NULL THEN 0
		     ELSE 1
		END DESC,
		spcvc.completing_id,
		spcvc.completing_number