CREATE PROCEDURE [Logistics].[TTN_GetForPrint]
	@ttn_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF EXISTS (SELECT 1 FROM Logistics.TTN t INNER JOIN Logistics.Shipping s ON s.shipping_id = t.shipping_id WHERE t.ttn_id = @ttn_id AND s.close_dt IS NULL)
	BEGIN
		RAISERROR('Отгрузка не закрыта',16,1)
		RETURN
	END	
	
	SELECT	t.ttn_id,
			oss.office_name                  src_office_name,
			oss.view_organization            src_view_organization,
			oss.office_address               src_office_address,
			oss.okpo_code                    src_okpo_code,
			oss.accountant,
			oss.authorized_shipping_position,
			oss.authorized_shipping_name,
			oss.made_shipping_position,
			oss.organization_name,
			osd.office_name                  dst_office_name,
			osd.view_organization            dst_view_organization,
			osd.office_address               dst_office_address,
			osd.okpo_code                    dst_okpo_code,
			CAST(s.close_dt AS DATETIME)     dt,
			v.brand_name                     vehicle_brand_name,
			v.number_plate                   vehicle_number_plate,
			d.driver_name,
			tv.brand_name                    towed_vehicle_brand_name,
			tv.number_plate                  towed_vehicle_number_plate,
			t.seal1, 
			t.seal2
	FROM	Logistics.TTN t   
			INNER JOIN	Logistics.Shipping s
				ON	s.shipping_id = t.shipping_id   
			LEFT JOIN	Settings.OfficeSetting oss
				ON	t.src_office_id = oss.office_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id   
			INNER JOIN	Logistics.Vehicle v
				ON	v.vehicle_id = t.vehicle_id   
			INNER JOIN	Logistics.Driver d
				ON	d.driver_id = t.driver_id   
			LEFT JOIN	Logistics.Vehicle tv
				ON	tv.vehicle_id = t.towed_vehicle_id
	WHERE	t.ttn_id = @ttn_id
			AND	t.is_deleted = 0
	
	SELECT	td.shkrm_id,
		 	CASE 
		 	     WHEN sma.stor_unit_residues_okei_id = td.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty
		 	     ELSE sma.amount * td.gross_mass / sma.gross_mass
		 	END amount,
			rmt.rmt_name,
			a.art_name,
			td.okei_id,
			o.symbol okei_symbol,
			td.qty,
			td.nds,
			td.gross_mass,
			su.su_name,
			cast(td.complite_dt AS DATETIME) complite_dt
	FROM	Logistics.TTNDetail td   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = td.ttn_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = td.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = td.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = td.okei_id
			INNER JOIN RefBook.SpaceUnit su
				ON td.su_id = su.su_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = td.shkrm_id
	WHERE	t.ttn_id = @ttn_id
			AND	t.is_deleted = 0