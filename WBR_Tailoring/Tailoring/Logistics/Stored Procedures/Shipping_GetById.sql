CREATE PROCEDURE [Logistics].[Shipping_GetById]
	@shipping_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.shipping_id,
			CAST(s.create_dt AS DATETIME) create_dt,
			s.create_employee_id,
			CAST(s.close_dt AS DATETIME)     close_dt,
			s.close_employee_id,
			CAST(s.complite_dt AS DATETIME) complite_dt,
			s.complite_employee_id,
			s.src_office_id,
			os.office_name                   src_office_name,
			CAST(s.rv AS BIGINT)             rv_bigint
	FROM	Logistics.Shipping s   
			INNER JOIN	Settings.OfficeSetting os
				ON	s.src_office_id = os.office_id
	WHERE	s.shipping_id = @shipping_id
	
	SELECT	t.ttn_id,
			t.src_office_id,
			oss.office_name     src_office_name,
			t.dst_office_id,
			osd.office_name     dst_office_name,
			t.seal1,
			t.seal2,
			t.create_employee_id,
			CAST(t.create_dt AS DATETIME) create_dt,
			t.vehicle_id,
			v.brand_name        vehicle_brand_name,
			v.number_plate      vehicle_number_plate,
			t.driver_id,
			d.driver_name,
			t.towed_vehicle_id,
			tv.brand_name       towed_vehicle_brand_name,
			tv.number_plate     towed_vehicle_number_plate,
			t.complite_employee_id,
			CAST(t.complite_dt AS DATETIME) complite_dt
	FROM	Logistics.TTN t   
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
	WHERE	t.shipping_id = @shipping_id
			AND	t.is_deleted = 0
	
	SELECT	td.ttn_id,
			t.src_office_id,
			oss.office_name     src_office_name,
			t.dst_office_id,
			osd.office_name     dst_office_name,
			td.shkrm_id,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = td.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * td.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * td.gross_mass / sma.gross_mass
			END amount,
			rmt.rmt_name,
			a.art_name,
			td.okei_id,
			o.symbol            okei_symbol,
			td.qty,
			smsd.state_name,
			sms.state_id,
			sp.place_name + '(' + os.office_name + ')' place_name
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
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = td.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp
			INNER JOIN Warehouse.ZoneOfResponse zor
			INNER JOIN Settings.OfficeSetting os
				ON os.office_id = zor.office_id
				ON zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = td.shkrm_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = td.shkrm_id
	WHERE	t.shipping_id = @shipping_id
			AND	t.is_deleted = 0
	
	SELECT	ta.ttn_id,
			t.src_office_id,
			oss.office_name     src_office_name,
			t.dst_office_id,
			osd.office_name     dst_office_name,
			ta.shkrm_id,
			sma.amount * ta.stor_unit_residues_qty / sma.stor_unit_residues_qty divergence_amount,
			rmt.rmt_name,
			a.art_name,
			ta.okei_id,
			o.symbol            okei_symbol,
			ta.divergence_qty,
			ta.comment,
			ta.write_of_qty,
			sma.amount * ta.write_of_qty / sma.stor_unit_residues_qty write_of_amount,
			ta.write_of_employee_id,
			ta.write_of_dt,
			ta.write_of_comment,
			ta.complite_employee_id,
			ta.complite_dt,
			smsd.state_name,
			sms.state_id,
			sp.place_name + '(' + os.office_name + ')' place_name
	FROM	Logistics.TTNDivergenceAct ta   
			INNER JOIN	Logistics.TTN t
				ON	t.ttn_id = ta.ttn_id   
			LEFT JOIN	Settings.OfficeSetting oss
				ON	t.src_office_id = oss.office_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = ta.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = ta.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = ta.okei_id
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = ta.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp
			INNER JOIN Warehouse.ZoneOfResponse zor
			INNER JOIN Settings.OfficeSetting os
				ON os.office_id = zor.office_id
				ON zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = ta.shkrm_id
			INNER JOIN Warehouse.SHKRawMaterialAmount sma
				ON sma.shkrm_id = ta.shkrm_id
	WHERE	t.shipping_id = @shipping_id
	
	SELECT ttn.ttn_id,
			t.ttns_id,
			sj.subject_name,
			an.art_name,
			s.sa,
			ts.ts_name,
			sp.place_name,
			ossp.office_name     place_office_name,
			ossp.office_id       place_office_id,
			sam.sample_id,
			s.sketch_id,
			sam.task_sample_id
	FROM	Logistics.TTN ttn
			INNER JOIN Logistics.TTNSample t 
				ON t.ttn_id = ttn.ttn_id  
			INNER JOIN	Manufactory.[Sample] sam
				ON	sam.sample_id = t.sample_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = sam.ts_id   
			INNER JOIN	Products.Sketch s
				ON	sam.sketch_id = s.sketch_id   
			LEFT JOIN	Warehouse.SampleOnPlace sop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting ossp
				ON	ossp.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = sop.place_id
				ON	sop.sample_id = sam.sample_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = s.brand_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
	WHERE	ttn.shipping_id = @shipping_id
	ORDER BY t.ttns_id