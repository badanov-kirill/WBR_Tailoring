CREATE PROCEDURE [Logistics].[TTN_GetForEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	
	SELECT	s.shipping_id,
			t.ttn_id,
			t.src_office_id,
			oss.office_name       src_office_name,
			t.dst_office_id,
			osd.office_name       dst_office_name,
			v.number_plate,
			v.brand_name          vehicle_brand_name
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id   
			INNER JOIN	Logistics.Shipping s
				ON	ts.office_id = s.src_office_id   
			INNER JOIN	Logistics.TTN t
				ON	t.shipping_id = s.shipping_id   
			INNER JOIN	Logistics.Vehicle v
				ON	v.vehicle_id = t.vehicle_id   
			LEFT JOIN	Settings.OfficeSetting oss
				ON	t.src_office_id = oss.office_id   
			LEFT JOIN	Settings.OfficeSetting osd
				ON	t.dst_office_id = osd.office_id
	WHERE	ets.employee_id = @employee_id
			AND	s.close_dt IS     NULL
