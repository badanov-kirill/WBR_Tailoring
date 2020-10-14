CREATE PROCEDURE [Planing].[TaskSelectionPassport_GetByCV]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tsp.tsp_id,
			CAST(tsp.create_dt AS DATETIME) create_dt,
			tsp.create_employee_id,
			CAST(tsp.print_dt AS DATETIME) print_dt,
			tsp.print_employee_id,
			CAST(tsp.close_dt AS DATETIME) close_dt,
			tsp.close_employee_id
	FROM	Planing.TaskSelectionPassport tsp
	WHERE	tsp.spcv_id = @spcv_id