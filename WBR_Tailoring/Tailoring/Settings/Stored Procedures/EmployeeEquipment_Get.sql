CREATE PROCEDURE [Settings].[EmployeeEquipment_Get]
	@employee_id INT = NULL,
	@equipment_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ee.employee_id,
			ee.equipment_id,
			es.office_id,
			es.brigade_id
	FROM	Settings.EmployeeEquipment ee
			INNER JOIN Settings.EmployeeSetting es ON es.employee_id = ee.employee_id
	WHERE	(@employee_id IS NULL OR ee.employee_id = @employee_id)
			AND	(@equipment_id IS NULL OR ee.equipment_id = @equipment_id)