
CREATE PROCEDURE [Warehouse].[SHKRawMaterialActualInfo_GetById]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smai.shkrm_id,
			smai.doc_id,
			smai.doc_type_id,
			smai.suppliercontract_id,
			smai.rmt_id,
			rmt.rmt_name,
			smai.art_id,
			a.art_name,
			smai.color_id,
			smai.su_id,
			smai.okei_id,
			o.symbol                   okei_symbol,
			smai.qty,
			smai.stor_unit_residues_okei_id,
			o2.symbol                  stor_unit_residues_okei_symbol,
			smai.stor_unit_residues_qty,
			sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			smai.dt,
			smai.employee_id,
			smai.frame_width,
			smai.is_defected,
			smai.is_deleted,
			sma.amount / sma.stor_unit_residues_qty su_price,
			(sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty) / smai.qty     price,
			smdd.descr                 defect_descr,
			smai.nds,
			smai.gross_mass,
			cc.color_name,
			s.supplier_name,
			smai.tissue_density,
			smai.fabricator_id
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = smai.stor_unit_residues_okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialDefectDescr smdd
				ON	smdd.shkrm_id = smai.shkrm_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = smai.shkrm_id
	WHERE	smai.shkrm_id = @shkrm_id