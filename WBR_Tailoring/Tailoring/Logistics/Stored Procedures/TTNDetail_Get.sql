CREATE PROCEDURE [Logistics].[TTNDetail_Get]
	@ttn_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	td.shkrm_id,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = td.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * td.gross_mass / sma.gross_mass
			END          amount,
			rmt.rmt_name,
			a.art_name,
			td.okei_id,
			o.symbol     okei_symbol,
			td.qty,
			CAST(smai.gross_mass AS DECIMAL(9,1)) / 1000 gross_mass
	FROM	Logistics.TTNDetail td   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = td.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = td.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = td.okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = td.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON smai.shkrm_id = sma.shkrm_id
	WHERE	td.ttn_id = @ttn_id
