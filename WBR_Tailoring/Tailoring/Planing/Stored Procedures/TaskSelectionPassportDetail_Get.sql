CREATE PROCEDURE [Planing].[TaskSelectionPassportDetail_Get]
	@tsp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tspd.shkrm_id,
			a.art_name,
			rmt.rmt_name,
			s.supplier_name,
			cc.color_name,
			tspd.quantity,
			o.symbol okei_symbol,
			smai.stor_unit_residues_qty
	FROM	Planing.TaskSelectionPassportDetail tspd   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = tspd.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = tspd.art_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = tspd.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = tspd.color_id
			LEFT JOIN Qualifiers.OKEI o
				ON tspd.okei_id = o.okei_id
			LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON tspd.shkrm_id = smai.shkrm_id
	WHERE	tspd.tsp_id = @tsp_id