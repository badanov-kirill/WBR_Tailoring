CREATE PROCEDURE [Reports].[PackingBox_AllInfo]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	pb.packing_box_id,
			es.employee_name              create_employee_name,
			ose.office_name               employee_office,
			oa_c.cnt,
			os.office_name,
			sp.place_name,
			CAST(pb.close_dt AS DATETIME) close_dt,
			CAST(pbop.dt AS DATETIME)     place_dt,
			CAST(CASE WHEN psfppb.packing_box_id IS NOT NULL THEN 1 ELSE 0 END AS BIT) plan_shipping,
			CAST(CASE WHEN sfppb.packing_box_id IS NOT NULL THEN 1 ELSE 0 END AS BIT) shipping,
			'PGBX' + CAST(pb.packing_box_id AS VARCHAR(10)) + '=' + RIGHT(
				CAST(SUBSTRING(hashbytes('MD5', CAST(pb.packing_box_id AS VARCHAR(10))), DATALENGTH(hashbytes('MD5', CAST(pb.packing_box_id AS VARCHAR(10)))) -1, 2) AS INT),
				3
			)                             shk
	FROM	Logistics.PackingBox pb   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = pb.create_employee_id   
			LEFT JOIN	Settings.OfficeSetting ose
				ON	ose.office_id = es.office_id   
			LEFT JOIN	Warehouse.PackingBoxOnPlace pbop
				ON	pbop.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	Logistics.PackingBoxDetail pbd
			      	WHERE	pbd.packing_box_id = pb.packing_box_id
			      )                       oa_c
	WHERE	oa_c.cnt > 0
	ORDER BY
		pb.packing_box_id