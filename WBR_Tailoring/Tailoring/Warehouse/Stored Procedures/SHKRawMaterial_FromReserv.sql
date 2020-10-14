CREATE PROCEDURE [Warehouse].[SHKRawMaterial_FromReserv]
	@rmt_id INT = NULL,
	@color_id INT = NULL,
	@art_name VARCHAR(12) = NULL,
	@frame_width SMALLINT = NULL,
	@shkrm_id INT = NULL,
	@color_name VARCHAR(20) = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @shkrm_state_expanded TINYINT = 3
	
	SELECT	TOP(2000) smai.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			smai.stor_unit_residues_qty,
			o.symbol     stor_unit_residues_okei_symbol,
			s.supplier_name,
			sma.amount / sma.stor_unit_residues_qty price_su,
			ISNULL(oa.qty, 0)       reserv_qty,
			smai.rmt_id,
			smai.frame_width,
			sp.place_name,
			zor.zor_name,
			os.office_name,
			smai.stor_unit_residues_qty - ISNULL(oa.qty, 0) free_qty
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Warehouse.SHKRawMaterialOnPlace smop
				ON	smop.shkrm_id = smai.shkrm_id   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.stor_unit_residues_okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = smai.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      )      oa
	WHERE	(@rmt_id IS NULL OR smai.rmt_id = @rmt_id)
			AND	(@color_id IS NULL OR smai.color_id = @color_id)
			AND	sms.state_id = @shkrm_state_expanded
			AND	(@art_name IS NULL OR a.art_name LIKE '%' + @art_name + '%')
			AND	(@frame_width IS NULL OR smai.frame_width = @frame_width)
			AND	(@shkrm_id IS NULL OR smai.shkrm_id = @shkrm_id)
			AND	(@color_name IS NULL OR cc.color_name LIKE '%' + @color_name + '%')
			AND (@office_id IS NULL OR zor.office_id = @office_id)
			AND smai.stor_unit_residues_qty > ISNULL(oa.qty, 0)
	ORDER BY
		cc.color_name,
		smai.stor_unit_residues_qty - oa.qty DESC