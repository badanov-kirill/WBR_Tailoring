CREATE PROCEDURE [Planing].[CoveringReserv_GetInfoBySPCVC]
	@covering_id INT,
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcvc.spcvc_id,
			c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			spcvc.rmt_id,
			rmt.rmt_name,
			spcvc.comment,
			spcvc.frame_width,
			ISNULL(oa_lay.consumption, spcvc.consumption) consumption,
			o.symbol     okei_symbol,
			cc.color_name,
			ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) qty,
			CASE 
			     WHEN cic.completing_id IS NULL THEN 0
			     ELSE 1
			END          is_cloth
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
			      	SELECT	TOP(1) l.frame_width, tl.tl_id
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
			      		tl.tl_id DESC, l.frame_width ASC
			      ) oa_lay_fw
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
	      					AND	l.frame_width = oa_lay_fw.frame_width
	      					AND tl.tl_id = oa_lay_fw.tl_id
				  )              oa_lay
	WHERE	spcvc.spcv_id = @spcv_id
	ORDER BY
		CASE 
		     WHEN cic.completing_id IS NULL THEN 0
		     ELSE 1
		END DESC,
		spcvc.completing_id,
		spcvc.completing_number
	
	SELECT	spcvc.spcvc_id,
			cr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			o.symbol     okei_symbol,
			cc.color_name,
			cr.qty       qty,
			a.art_name,
			os2.office_id,
			os2.office_name,
			stpl.place_name,
			CASE 
			     WHEN cis.cisr_id IS NULL THEN 0
			     ELSE 1
			END          is_covering
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.CoveringReserv cr
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
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace stpl
				ON	stpl.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = stpl.zor_id   
			INNER JOIN	Settings.OfficeSetting os2
				ON	zor.office_id = os2.office_id
				ON	smop.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Planing.CoveringIssueSHKRm cis
				ON	cis.covering_id = cr.covering_id
				AND	cis.shkrm_id = cr.shkrm_id
	WHERE	spcvc.spcv_id = @spcv_id
			AND	cr.covering_id = @covering_id
	
	SELECT	panc.color_cod,
			panc.is_main,
			c.color_name
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticleNomenclatureColor panc
				ON	panc.pan_id = pan.pan_id   
			INNER JOIN	Products.Color c
				ON	c.color_cod = panc.color_cod
	WHERE	spcv.spcv_id = @spcv_id
	ORDER BY
		CASE 
		     WHEN panc.is_main = 1 THEN 0
		     ELSE 1
		END,
		panc.color_cod
	
	SELECT	ts.ts_name,
			spcvt.cnt,
			ISNULL(c.perimeter, spp.perimetr) perimeter,
			spcvt.ts_id,
			spcvtc.cutting_qty cutting_qty,
			spcvtc.cut_write_off
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp			
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = spcv.spcv_id 
			LEFT JOIN	Products.SketchPatternPerimetr spp
				ON	spp.ts_id = spcvt.ts_id
				AND	spp.sketch_id = sp.sketch_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id     
			LEFT JOIN	Manufactory.Cutting c
				ON	c.spcvts_id = spcvt.spcvts_id
			LEFT JOIN Planing.SketchPlanColorVariantTSCounter spcvtc
				ON spcvtc.spcvts_id = spcvt.spcvts_id
	WHERE	spcv.spcv_id = @spcv_id
	ORDER BY
		ts.ts_name