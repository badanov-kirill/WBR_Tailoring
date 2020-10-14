CREATE PROCEDURE [Logistics].[TransferBoxSpecial_GetBySPCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tbs.transfer_box_id,
			CAST(tb.create_dt AS DATETIME) create_dt,
			os.office_name,
			CAST(tbs.plan_shipping_dt AS DATETIME) plan_shipping_dt,
			CAST(tbs.print_dt AS DATETIME) print_dt,
			es.employee_name print_employee_name,
			tbs.office_id
	FROM	Logistics.TransferBoxSpecial tbs   
			INNER JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = tbs.transfer_box_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = tbs.office_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	tbs.print_employee_id = es.employee_id
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	Logistics.TransferBoxSpecialSPCV tbss
	     		WHERE	tbss.transfer_box_id = tbs.transfer_box_id
	     				AND	tbss.spcv_id = @spcv_id
	     	)