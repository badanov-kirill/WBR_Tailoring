CREATE PROCEDURE [Warehouse].[Imprest_GetList]
	@dt_start DATETIME2(0),
	@dt_finish DATETIME2(0),
	@imprest_employee_id INT = NULL,
	@imprest_office_id INT = NULL,
	@is_not_approve BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	i.imprest_id,
			CAST(i.create_dt AS DATETIME) create_dt,
			i.create_employee_id,
			i.imprest_office_id,
			os.office_name,
			i.imprest_employee_id,
			i.comment,
			i.is_deleted,
			i.edit_employee_id,
			i.approve_employee_id,
			CAST(i.approve_dt AS DATETIME) approve_dt,
			CAST(i.rv AS BIGINT) rv_bigint,
			i.cash_sum
	FROM	Warehouse.Imprest i   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = i.imprest_office_id
	WHERE	i.create_dt >= @dt_start
			AND	i.create_dt <= @dt_finish
			AND	(@imprest_employee_id IS NULL OR i.imprest_employee_id = @imprest_employee_id)
			AND	(@imprest_office_id IS NULL OR i.imprest_office_id = @imprest_office_id)
			AND	(@is_not_approve IS NULL OR (@is_not_approve = 1 AND i.approve_dt IS NULL) OR (@is_not_approve = 0 AND i.approve_dt IS NOT NULL))