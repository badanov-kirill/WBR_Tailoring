CREATE PROCEDURE [Logistics].[TTN_GetDivergence]
	@shipping_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	td.ttn_id,
			t.src_office_id,
			oss.office_name           src_office_name,
			t.dst_office_id,
			osd.office_name           dst_office_name,
			td.shkrm_id,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = td.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * td.gross_mass / sma.gross_mass
			END amount,
			rmt.rmt_name,
			a.art_name,
			td.okei_id,
			o.symbol                  okei_symbol,
			td.qty
	FROM	Logistics.TTNDetail td   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = td.ttn_id   
			LEFT JOIN	Settings.OfficeSetting oss
				ON	t.src_office_id = oss.office_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = td.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = td.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = td.okei_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = td.shkrm_id
	WHERE	t.shipping_id = @shipping_id
			AND	t.is_deleted = 0
			AND	td.complite_dt IS     NULL
	UNION
	SELECT	td.ttn_id,
			t.src_office_id,
			oss.office_name,
			t.dst_office_id,
			osd.office_name,
			td.shkrm_id,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = td.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * td.gross_mass / sma.gross_mass
			END,
			rmt.rmt_name,
			a.art_name,
			td.okei_id,
			o.symbol,
			td.divergence_qty
	FROM	Logistics.TTNDivergenceAct td   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = td.ttn_id   
			LEFT JOIN	Settings.OfficeSetting oss
				ON	t.src_office_id = oss.office_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = td.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = td.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = td.okei_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = td.shkrm_id
	WHERE	t.shipping_id = @shipping_id
			AND	t.is_deleted = 0