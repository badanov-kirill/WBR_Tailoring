CREATE PROCEDURE [Planing].[Covering_GetInfo]
	@covering_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	SELECT	cr.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			o.symbol        stor_unit_residues_okei_symbol,
			cc.color_name,
			SUM(cr.qty)     qty,
			a.art_name,
			os2.office_id,
			os2.office_name,
			stpl.place_name,
			smsd.state_name
	FROM	Planing.CoveringReserv cr   
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
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = cr.shkrm_id
	WHERE	cr.covering_id = @covering_id
	GROUP BY
		cr.shkrm_id,
		rmt.rmt_name,
		smai.frame_width,
		o.symbol,
		cc.color_name,
		a.art_name,
		os2.office_id,
		os2.office_name,
		stpl.place_name,
		smsd.state_name
	
	SELECT	cis.shkrm_id,
			rmt.rmt_name,
			smai.frame_width,
			a.art_name,
			cc.color_name,
			cis.stor_unit_residues_qty,
			o2.symbol stor_unit_residues_okei_symbol,
			CAST(cis.return_dt AS DATETIME) return_dt,
			cis.return_stor_unit_residues_qty return_qty
	FROM	Planing.CoveringIssueSHKRm cis   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = cis.stor_unit_residues_okei_id
	WHERE	cis.covering_id = @covering_id
	ORDER BY cis.cisr_id