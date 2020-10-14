CREATE PROCEDURE [Warehouse].[AssemblyList_Get]
	@start_dt dbo.SECONDSTIME,
	@finish_dt dbo.SECONDSTIME,
	@workshop_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	al.al_id,
			al.workshop_id,
			w.workshop_name,
			CAST(al.create_dt AS DATETIME) create_dt,
			al.create_employee_id,
			cast(al.shipping_dt AS DATETIME) shipping_dt,
			CAST(al.close_dt AS DATETIME) close_dt,
			al.close_employee_id
	FROM	Warehouse.AssemblyList al   
			LEFT JOIN	Warehouse.Workshop w
				ON	al.workshop_id = w.workshop_id
	WHERE	al.create_dt >= @start_dt
			AND	al.create_dt <= @finish_dt
			AND	(@workshop_id IS NULL OR al.workshop_id = @workshop_id)
