CREATE PROCEDURE [Warehouse].[Cancellation_GetInfo]
	@cancellation_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.cancellation_id,
			CAST(c.create_dt AS DATETIME) create_dt,
			c.create_employee_id,
			c.office_id,
			os.office_name,
			c.cancellation_year,
			c.cancellation_month,
			c.close_employee_id,
			CAST(c.close_dt AS DATETIME) close_dt
	FROM	Warehouse.Cancellation c   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id
	WHERE	c.cancellation_id = @cancellation_id
	
	SELECT	csr.shkrm_id,
			a.art_name,
			rmt.rmt_name,
			cc.color_name,
			s.supplier_name,
			o.symbol      okei_symbol,
			csr.qty,
			o2.symbol     stor_unit_residues_okei_symbol,
			csr.stor_unit_residues_qty,
			sma.amount * csr.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			csr.frame_width,
			csr.is_defected,
			csr.employee_id,
			CAST(csr.dt AS DATETIME) dt,
			smlsd.state_name logic_state_name
	FROM	Warehouse.CancellationShkRM csr   
			INNER JOIN	Material.Article a
				ON	a.art_id = csr.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = csr.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = csr.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = csr.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = csr.stor_unit_residues_okei_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = csr.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = csr.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialLogicState smls
			INNER JOIN Warehouse.SHKRawMaterialLogicStateDict smlsd
				ON smlsd.state_id = smls.state_id
				ON smls.shkrm_id = csr.shkrm_id 
	WHERE	csr.cancellation_id = @cancellation_id