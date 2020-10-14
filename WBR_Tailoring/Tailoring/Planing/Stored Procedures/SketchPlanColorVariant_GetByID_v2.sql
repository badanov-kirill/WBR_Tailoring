CREATE PROCEDURE [Planing].[SketchPlanColorVariant_GetByID_v2]
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
			ISNULL(oa_lay.consumption, spcvc.consumption) consumption,
			o.symbol okei_symbol,
			spcvc.color_id,
			cc.color_name,
			ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty)  qty,
			oar.qty                          reserv_qty,
			CASE 
			     WHEN cic.completing_id IS NULL THEN 0
			     ELSE 1
			END                              is_cloth,
			oa_rmt_res.x rmt_name_res,
			ISNULL(oar.qty, 0) - ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) diff_qty,
			CASE 
			     WHEN oa_lay.consumption IS NULL THEN 0
			     ELSE 1
			END is_layout		
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
	      			SELECT v.rmt_name + ' / ' + ISNULL(CAST(v.frame_width AS VARCHAR(10)), '') +' / ' + v.art_name + ' / ' + v.color_name +' ; '
	      			FROM (
	      			SELECT rmt2.rmt_name, a.art_name, cc2.color_name, smai.frame_width
	      			FROM	Warehouse.SHKRawMaterialReserv smr   
	      					INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
	      						ON	smai.shkrm_id = smr.shkrm_id   
	      					INNER JOIN	Material.Article a
	      						ON	a.art_id = smai.art_id
	      					INNER JOIN Material.RawMaterialType rmt2
	      						ON rmt2.rmt_id = smai.rmt_id
	      					INNER JOIN Material.ClothColor cc2 
	      						ON cc2.color_id = smai.color_id
	      			WHERE	smr.spcvc_id = spcvc.spcvc_id
	      			GROUP BY rmt2.rmt_name, a.art_name, cc2.color_name, smai.frame_width
	      			) v
	      			FOR XML PATH('')
				  )                                  oa_rmt_res(x)
			OUTER APPLY (SELECT	TOP(1) l.frame_width, tl.tl_id
					FROM	Manufactory.TaskLayout tl   
							INNER JOIN	Manufactory.TaskLayoutDetail tld
								ON	tld.tl_id = tl.tl_id   
							INNER JOIN	Manufactory.Layout l
								ON	l.layout_id = tld.layout_id
					WHERE	tl.spcv_id = spcv.spcv_id
							AND	l.base_completing_id = spcvc.completing_id
							AND	l.base_completing_number = spcvc.completing_number
							AND	l.is_deleted = 0
					ORDER BY
						tl.tl_id DESC, l.frame_width ASC) oa_lay_fw
			OUTER APPLY (
					SELECT	AVG(l.base_consumption) consumption
					FROM	Manufactory.TaskLayout tl   
							INNER JOIN	Manufactory.TaskLayoutDetail tld
								ON	tld.tl_id = tl.tl_id   
							INNER JOIN	Manufactory.Layout l
								ON	l.layout_id = tld.layout_id
					WHERE	tl.spcv_id = spcv.spcv_id
							AND	l.base_completing_id = spcvc.completing_id
							AND	l.base_completing_number = spcvc.completing_number
							AND	l.is_deleted = 0
							AND l.frame_width = oa_lay_fw.frame_width
							AND tl.tl_id = oa_lay_fw.tl_id
			) oa_lay
	WHERE	spcvc.spcv_id = @spcv_id
	ORDER BY
		CASE 
		     WHEN cic.completing_id IS NULL THEN 0
		     ELSE 1
		END DESC,
		spcvc.completing_id,
		spcvc.completing_number