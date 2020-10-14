CREATE PROCEDURE [Planing].[Covering_GetInfoBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @covering_id INT
	
	SELECT	@covering_id = cd.covering_id
	FROM	Planing.CoveringDetail cd
	WHERE	cd.spcv_id = @spcv_id
			AND	cd.is_deleted = 0
	
	SELECT	c.covering_id,
			CAST(c.create_dt AS DATETIME) dt,
			c.create_employee_id
	FROM	Planing.Covering c
	WHERE	c.covering_id = @covering_id
	
	SELECT	spcv.spcv_id,
			pa.sa + pan.sa sa,
			pan.nm_id,
			an.art_name,
			sj.subject_name,
			b.brand_name,
			pa.sketch_id
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
	
	SELECT	spcvc.spcv_id,
			spcvc.spcvc_id,
			c.completing_name + ' ' + CAST(spcvc.completing_number AS VARCHAR(10)) completing,
			spcvc.rmt_id,
			rmt.rmt_name,
			spcvc.comment,
			spcvc.frame_width,
			o.symbol     okei_symbol,
			cc.color_name,
			CASE 
			     WHEN cic.completing_id IS NULL THEN 0
			     ELSE 1
			END          is_cloth
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = cd.spcv_id   
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
	WHERE	cd.covering_id = @covering_id
			AND	cd.is_deleted = 0
	
	SELECT	smr.spcvc_id,
			smr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			o.symbol     okei_symbol,
			cc.color_name,
			smr.qty      qty,
			a.art_name,
			os2.office_id,
			os2.office_name,
			stpl.place_name,
			CASE 
			     WHEN isr.shkrm_id IS NOT NULL THEN 1
			     ELSE 0
			END          is_issue,
			smsd.state_name
	FROM	Planing.CoveringReserv smr   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace stpl
				ON	stpl.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = stpl.zor_id   
			INNER JOIN	Settings.OfficeSetting os2
				ON	zor.office_id = os2.office_id
				ON	smop.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Planing.CoveringIssueSHKRm isr
				ON	smr.shkrm_id = isr.shkrm_id
				AND	smr.covering_id = isr.covering_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = smr.shkrm_id
	WHERE	smr.covering_id = @covering_id
	
	SELECT	isr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			a.art_name,
			cc.color_name,
			isr.qty,
			o.symbol      okei_symbol,
			isr.stor_unit_residues_qty,
			o2.symbol     stor_unit_residues_okei_symbol,
			CASE 
			     WHEN oar.shkrm_id IS NOT NULL THEN 1
			     ELSE 0
			END           is_reserv,
			CAST(isr.return_dt AS DATETIME) return_dt
	FROM	Planing.CoveringIssueSHKRm isr   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = isr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = isr.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = isr.stor_unit_residues_okei_id   
			OUTER APPLY (
			      	SELECT	TOP(1) ir.shkrm_id
			      	FROM	Planing.CoveringReserv ir
			      	WHERE	ir.covering_id = isr.covering_id
			      			AND	ir.shkrm_id = isr.shkrm_id
			      )       oar
	WHERE	isr.covering_id = @covering_id