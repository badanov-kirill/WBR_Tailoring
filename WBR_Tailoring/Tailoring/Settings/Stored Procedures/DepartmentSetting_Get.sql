CREATE PROCEDURE [Settings].[DepartmentSetting_Get]
	@department_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ds.department_id,
			ds.department_name,
			ds.office_id,
			ds.dt,
			ds.employee_id,
			os.office_name
	FROM	Settings.DepartmentSetting ds   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = ds.office_id
	WHERE	(ds.department_id = @department_id
			OR	@department_id IS NULL)
