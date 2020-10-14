CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompleting_GetReserv]
	@spcvc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smr.shkrm_id,
			rmt.rmt_name,
			cc.color_name,
			smai.frame_width,
			smr.quantity     reserv_qty,
			o1.symbol        reserv_okei_symbol,
			smai.stor_unit_residues_qty,
			o2.symbol        stor_unit_residues_okei_symbol,
			smr.spcvc_id,
			a.art_name,
			os.office_name,
			sp.place_name,
			rmtp.rmtp_id
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id  
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id 
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Qualifiers.OKEI o1
				ON	o1.okei_id = smr.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = smai.stor_unit_residues_okei_id
			INNER JOIN Material.Article a
				ON a.art_id = smai.art_id
			LEFT JOIN Warehouse.SHKRawMaterialOnPlace smop
			INNER JOIN Warehouse.StoragePlace sp
				ON sp.place_id = smop.place_id
			INNER JOIN Warehouse.ZoneOfResponse zor
				ON zor.zor_id = sp.zor_id
			INNER JOIN Settings.OfficeSetting os
				ON os.office_id = zor.office_id
				ON smop.shkrm_id = smr.shkrm_id
			LEFT JOIN Material.RawMaterialTypePhoto rmtp
				ON rmtp.art_id = smai.art_id 
				AND rmtp.rmt_id = smai.rmt_id 
				AND rmtp.color_id = smai.color_id 
				AND rmtp.supplier_id = sc.supplier_id 
				AND ISNULL(smai.frame_width, 0) =ISNULL(rmtp.frame_width, 0)    
	WHERE	spcvc.spcvc_id = @spcvc_id