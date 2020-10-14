CREATE PROCEDURE [Warehouse].[PackingBoxOnPlace_Get]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	os.office_name,
			sp.place_name,
			pbop.packing_box_id,
			CAST(pb.start_packaging_dt AS DATETIME) start_packaging_dt,
			CAST(pb.close_dt AS DATETIME) close_dt,
			CAST(pbop.dt AS DATETIME)     place_dt,
			CASE 
			     WHEN psfppb.packing_box_id IS NOT NULL THEN 1
			     ELSE 0
			END                           plan_shipping,
			CASE 
			     WHEN sfppb.packing_box_id IS NOT NULL THEN 1
			     ELSE 0
			END                           shipping
	FROM	Warehouse.PackingBoxOnPlace pbop   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = pbop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			INNER JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = pbop.packing_box_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			LEFT JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON	psfppb.packing_box_id = pb.packing_box_id   
			LEFT JOIN	Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON	sfppb.packing_box_id = pb.packing_box_id
	WHERE	(@office_id IS NULL OR zor.office_id = @office_id)
			AND	psfppb.packing_box_id IS NULL
			AND	sfppb.packing_box_id IS NULL
			AND	EXISTS (
			   		SELECT	1
			   		FROM	Logistics.PackingBoxDetail pbd
			   		WHERE	pbd.packing_box_id = pbop.packing_box_id
			   	)
			