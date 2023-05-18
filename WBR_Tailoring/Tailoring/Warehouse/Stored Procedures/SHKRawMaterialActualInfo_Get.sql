CREATE PROCEDURE [Warehouse].[SHKRawMaterialActualInfo_Get]
	@rmt_id INT = NULL,
	@art_name VARCHAR(12) = NULL,
	@supplier_id INT = NULL,
	@color_id INT = NULL,
	@min_frame_width SMALLINT = NULL,
	@max_frame_width SMALLINT = NULL,
	@min_price DECIMAL(9, 2) = NULL,
	@max_price DECIMAL(9, 2) = NULL,
	@place_name VARCHAR(50) = NULL,
	@photo BIT = NULL,
	@state_id INT = NULL,
	@doc_id INT = NULL,
	@base_state_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmt.rmt_name,
			cc.color_name,
			a.art_name,
			smai.stor_unit_residues_qty,
			o2.symbol     stor_unit_residues_okei_symbol,
			smai.frame_width,
			smai.shkrm_id,
			sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			smai.qty,
			o.symbol      okei_symbol,
			su.su_name,
			s.supplier_name,
			sma.amount / sma.stor_unit_residues_qty su_price,
			(sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty) / smai.qty price,
			sp.place_name,
			os.office_name,
			smsd.state_name,
			smai.tissue_density,
			CAST(sm.dt_mapping AS DATETIME) dt_mapping,
			smai.stor_unit_residues_qty - ISNULL(oa_res.resrv_qtu, 0) free_qty,
			rmtp.rmtp_id,
			smlsd.state_name logic_state_name,
			smai.fabricator_id,
			f.fabricator_name
	FROM	Warehouse.SHKRawMaterialActualInfo smai  
			INNER JOIN	Settings.Fabricators f
				ON	f.fabricator_id = smai.fabricator_id
			INNER JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = smai.shkrm_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = smai.stor_unit_residues_okei_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = smai.su_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	smai.shkrm_id = sms.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id
			LEFT JOIN Material.RawMaterialTypePhoto rmtp
				ON rmtp.art_id = smai.art_id 
				AND rmtp.rmt_id = smai.rmt_id 
				AND rmtp.color_id = smai.color_id 
				AND rmtp.supplier_id = sc.supplier_id 
				AND ISNULL(smai.frame_width, 0) =ISNULL(rmtp.frame_width, 0)   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) resrv_qtu
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      )       oa_res
			LEFT JOIN Warehouse.SHKRawMaterialLogicState smls
			INNER JOIN Warehouse.SHKRawMaterialLogicStateDict smlsd
				ON smlsd.state_id = smls.state_id
				ON smls.shkrm_id = sm.shkrm_id
	WHERE	(@supplier_id IS NULL OR s.supplier_id = @supplier_id)
			AND	(@rmt_id IS NULL OR smai.rmt_id = @rmt_id)
			AND	(@art_name IS NULL OR a.art_name = @art_name)
			AND	(@color_id IS NULL OR smai.color_id = @color_id)
			AND	(@min_frame_width IS NULL OR smai.frame_width >= @min_frame_width)
			AND	(@max_frame_width IS NULL OR smai.frame_width <= @max_frame_width)
			AND	(@min_price IS NULL OR sma.amount / sma.stor_unit_residues_qty >= @min_price)
			AND	(@max_price IS NULL OR sma.amount / sma.stor_unit_residues_qty <= @max_price)
			AND	(@place_name IS NULL OR sp.place_name = @place_name)
			AND (@photo IS NULL OR (@photo = 1 AND rmtp.rmtp_id IS NOT NULL) OR (@photo = 0 AND rmtp.rmtp_id IS NULL))
			AND (@state_id IS NULL OR smls.state_id = @state_id)
			AND (@doc_id IS NULL OR smai.doc_id = @doc_id)
			AND (@base_state_id IS NULL OR sms.state_id = @base_state_id)