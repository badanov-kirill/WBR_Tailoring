CREATE PROCEDURE [Logistics].[TransferSetting_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.office_id       src_office_id,
			os.office_name     src_office_name
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = ts.office_id
	WHERE	ets.employee_id = @employee_id
	
	SELECT	tso.office_id      dst_office_id,
			os.office_name     dst_office_name
	FROM	Settings.EmployeeTransferSetting ets   
			INNER JOIN	Settings.TransferSetting ts
				ON	ts.ts_id = ets.ts_id   
			INNER JOIN	Settings.TransferSettingOfiice tso
				ON	tso.ts_id = ts.ts_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = tso.office_id
	WHERE	ets.employee_id = @employee_id