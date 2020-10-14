CREATE PROCEDURE [Settings].[EmployeeSetting_Get]
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	es.employee_id,
			es.office_id,
			es.employee_name,
			es.dt,
			es.change_employee_id,
			es.department_id,
			os.office_name,
			ds.department_name
	FROM	Settings.EmployeeSetting es   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = es.office_id   
			LEFT JOIN	Settings.DepartmentSetting ds
				ON	ds.department_id = es.department_id
	WHERE	(@employee_id IS NULL OR es.employee_id = @employee_id)