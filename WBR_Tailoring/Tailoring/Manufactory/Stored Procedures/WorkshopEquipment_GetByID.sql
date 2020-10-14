CREATE PROCEDURE [Manufactory].[WorkshopEquipment_GetByID]
	@we_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	we.we_id,
			we.equipment_id,
			we.article,
			we.serial_num,
			we.stuff_shk_id,
			we.comment,
			we.zor_id,
			CAST(we.dt AS DATETIME) dt,
			we.employee_id,
			we.work_hour
	FROM	Manufactory.WorkshopEquipment we   
	WHERE	we.we_id = @we_id