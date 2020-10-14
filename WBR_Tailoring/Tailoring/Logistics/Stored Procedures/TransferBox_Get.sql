CREATE PROCEDURE [Logistics].[TransferBox_Get]
	@is_no_close BIT = NULL,
	@start_dt DATETIME2(0) = NULL,
	@finish_dt DATETIME2(0) = NULL,
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tb.transfer_box_id,
			os.office_name,
			CAST(tb.create_dt AS DATETIME) create_dt,
			es.employee_name      create_employee_name,
			CAST(tb.close_dt AS DATETIME) close_dt,
			esc.employee_name     close_employee_name,
			CASE 
			     WHEN tbs.transfer_box_id IS NULL THEN 0
			     ELSE 1
			END is_special,
			CAST(tb.plan_shipping_dt AS DATETIME) plan_shipping_dt
	FROM	Logistics.TransferBox tb   
			LEFT JOIN	Settings.EmployeeSetting es   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = es.office_id
				ON	tb.create_employee_id = es.employee_id   
			LEFT JOIN	Settings.EmployeeSetting esc
				ON	tb.close_employee_id = esc.employee_id
			LEFT JOIN Logistics.TransferBoxSpecial tbs
				ON tbs.transfer_box_id = tb.transfer_box_id
	WHERE	(@is_no_close IS NULL OR (@is_no_close = 1 AND tb.close_dt IS NULL) OR (@is_no_close = 0 AND tb.close_dt IS NOT NULL))
			AND	(@office_id IS NULL OR es.office_id = @office_id)
			AND	(@start_dt IS NULL OR tb.create_dt >= @start_dt)
			AND	(@finish_dt IS NULL OR tb.create_dt <= @finish_dt)