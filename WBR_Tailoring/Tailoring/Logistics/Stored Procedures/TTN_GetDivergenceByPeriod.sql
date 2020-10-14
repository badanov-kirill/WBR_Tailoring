CREATE PROCEDURE [Logistics].[TTN_GetDivergenceByPeriod]
	@start_dt DATE,
	@finish_dt DATE,
	@src_office_id INT = NULL,
	@dst_office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.shipping_id,
			CAST(s.close_dt AS DATETIME)     close_dt,
			td.ttn_id,
			oss.office_name                  src_office_name,
			osd.office_name                  dst_office_name,
			td.shkrm_id,
			sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			rmt.rmt_name,
			a.art_name,
			o.symbol                         okei_symbol,
			td.qty
	FROM	Logistics.TTNDetail td   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = td.ttn_id   
			INNER JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id   
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
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = td.shkrm_id
	WHERE	t.is_deleted = 0
			AND	td.complite_dt IS NULL
			AND	s.close_dt >= @start_dt
			AND	s.close_dt < @finish_dt
			AND	(@src_office_id IS NULL OR t.src_office_id = @src_office_id)
			AND	(@dst_office_id IS NULL OR t.dst_office_id = @dst_office_id)
	UNION
	SELECT	s.shipping_id,
			CAST(s.close_dt AS DATETIME),
			td.ttn_id,
			oss.office_name,
			osd.office_name,
			td.shkrm_id,
			sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty,
			rmt.rmt_name,
			a.art_name,
			o.symbol,
			td.divergence_qty
	FROM	Logistics.TTNDivergenceAct td   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = td.ttn_id   
			INNER JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id   
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
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = td.shkrm_id
	WHERE	t.is_deleted = 0
			AND	s.close_dt >= @start_dt
			AND	s.close_dt < @finish_dt
			AND	(@src_office_id IS NULL OR t.src_office_id = @src_office_id)
			AND	(@dst_office_id IS NULL OR t.dst_office_id = @dst_office_id)