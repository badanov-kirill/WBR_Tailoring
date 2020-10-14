CREATE PROCEDURE [Settings].[EmployeeTransferSetting_Get]
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ets.employee_id,
			ets.ts_id,
			ts.setting_name,
			ts.office_id
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id
	WHERE	ets.employee_id = @employee_id
			OR	@employee_id IS NULL
	
