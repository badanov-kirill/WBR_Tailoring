CREATE PROCEDURE [Logistics].[TransferBoxSpecial_Get]
	@office_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tbs.transfer_box_id,
			CAST(tb.create_dt AS DATETIME) create_dt,
			os.office_name,
			cast(tbs.plan_shipping_dt AS DATETIME) plan_shipping_dt,
			CAST(tbs.print_dt AS DATETIME) print_dt,
			es.employee_name     print_employee_name,
			tbs.office_id
	FROM	Logistics.TransferBoxSpecial tbs   
			INNER JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = tbs.transfer_box_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = tbs.office_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	tbs.print_employee_id = es.employee_id
	WHERE	tb.close_dt IS       NULL
			AND (@office_id IS NULL OR tbs.office_id = @office_id)