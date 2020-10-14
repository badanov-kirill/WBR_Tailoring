CREATE PROCEDURE [Warehouse].[Inventory_Get]
	@start_dt DATETIME2(0) = NULL,
	@finish_dt DATETIME2(0) = NULL,
	@from_wh BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @dt DATE = GETDATE()
	
	SELECT	i.inventory_id,
			CAST(i.plan_start_dt AS DATETIME) plan_start_dt,
			CAST(i.plan_finish_dt AS DATETIME) plan_finish_dt,
			CAST(i.create_dt AS DATETIME) create_dt,
			escr.employee_name               create_employee_name,
			it.it_name,
			i.comment,
			rmt.rmt_name,
			CAST(i.close_dt AS DATETIME)     close_dt,
			escl.employee_name               close_employee_name,
			i.lost_sum
	FROM	Warehouse.Inventory i   
			INNER JOIN	Warehouse.InventoryType it
				ON	it.it_id = i.it_id   
			INNER JOIN	Settings.EmployeeSetting escr
				ON	i.create_employee_id = escr.employee_id   
			LEFT JOIN	Settings.EmployeeSetting escl
				ON	i.close_employee_id = escl.employee_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = i.rmt_id
	WHERE	(@start_dt IS NULL OR i.create_dt >= @start_dt)
			AND	(@finish_dt IS NULL OR i.create_dt <= @finish_dt)
			AND	(@from_wh = 0 OR (i.plan_start_dt <= @dt AND i.plan_finish_dt >= @dt AND i.close_dt IS NULL))
			AND i.is_deleted = 0