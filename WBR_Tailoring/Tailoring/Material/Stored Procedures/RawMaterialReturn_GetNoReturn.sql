CREATE PROCEDURE [Material].[RawMaterialReturn_GetNoReturn]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmr.rmr_id,
			rmr.doc_id,
			rmr.doc_type_id,
			CAST(rmr.create_dt AS DATETIME) create_dt,
			rmr.create_employee_id,
			CAST(rmr.return_dt AS DATETIME) return_dt,
			rmr.return_employee_id,
			rmr.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			s.supplier_name,
			rmr.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			rmr.frame_width,
			rmr.is_defected,
			sma.amount * rmr.stor_unit_residues_qty / sma.stor_unit_residues_qty amount
	FROM	Material.RawMaterialReturn rmr   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmr.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmr.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rmr.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmr.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmr.stor_unit_residues_okei_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = rmr.shkrm_id
	WHERE	rmr.return_dt IS               NULL