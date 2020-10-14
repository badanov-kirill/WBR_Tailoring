CREATE PROCEDURE [Manufactory].[WorkshopEquipment_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	we.we_id,
			we.equipment_id,
			e.equipment_name,
			we.article,
			we.serial_num,
			we.stuff_shk_id,
			we.comment,
			we.zor_id,
			zor.zor_name,
			zor.office_id,
			os.office_name,
			CAST(we.dt AS DATETIME) dt,
			we.employee_id, 
			we.work_hour			
	FROM	Manufactory.WorkshopEquipment we   
			INNER JOIN	Technology.Equipment e
				ON	e.equipment_id = we.equipment_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = we.zor_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
	WHERE	we.is_deleted = 0