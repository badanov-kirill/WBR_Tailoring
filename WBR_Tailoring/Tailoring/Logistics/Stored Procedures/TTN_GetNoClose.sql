CREATE PROCEDURE [Logistics].[TTN_GetNoClose]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	t.ttn_id,
			t.src_office_id,
			oss.office_name       src_office_name,
			t.dst_office_id,
			osd.office_name       dst_office_name,
			t.seal1,
			t.seal2,
			t.create_employee_id,
			CAST(t.create_dt AS DATETIME) create_dt,
			t.vehicle_id,
			v.brand_name          vehicle_brand_name,
			v.number_plate        vehicle_number_plate,
			t.driver_id,
			d.driver_name,
			t.towed_vehicle_id,
			tv.brand_name         towed_vehicle_brand_name,
			tv.number_plate       towed_vehicle_number_plate,
			t.complite_employee_id,
			CAST(t.complite_dt AS DATETIME) complite_dt
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
	WHERE	t.is_deleted = 0
			AND	s.close_dt IS     NULL