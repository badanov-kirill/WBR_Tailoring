
CREATE PROCEDURE [Material].[RawMaterialExchange_FindByShk]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @supplier_id INT
	
	SELECT	@supplier_id = sc.supplier_id
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id
	WHERE	smai.shkrm_id = @shkrm_id
	
	SELECT	rme.rme_id,
			rme.doc_id,
			rme.doc_type_id,
			CAST(rme.create_dt AS DATETIME) create_dt,
			rme.create_employee_id,
			CAST(rme.return_dt AS DATETIME) return_dt,
			rme.return_employee_id,
			rme.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			s.supplier_name,
			rme.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			rme.frame_width,
			rme.is_defected,
			rmt2.rmt_name                  need_rmt_name,
			cc2.color_name                 need_color_name,
			rme.need_qty,
			o2.symbol                      need_okei_symbol,
			sma.amount * rme.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			ri.fabricator_id,
			f.fabricator_name
	FROM	Material.RawMaterialExchange rme   
			INNER JOIN Material.RawMaterialIncome ri 
				ON  ri.doc_id = rme.doc_id and ri.doc_type_id = rme.doc_type_id
			INNER JOIN Settings.Fabricators f
				ON f.fabricator_id = ri.fabricator_id
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rme.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rme.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rme.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rme.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rme.stor_unit_residues_okei_id   
			INNER JOIN	Material.RawMaterialType rmt2
				ON	rmt2.rmt_id = rme.need_rmt_id   
			INNER JOIN	Material.ClothColor cc2
				ON	cc2.color_id = rme.need_color_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = rme.need_okei_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = rme.shkrm_id
	WHERE	sc.supplier_id = @supplier_id
			AND	rme.change_dt IS           NULL