CREATE PROCEDURE [Settings].[Brigade_Get]
	@and_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	b.brigade_id,
			b.brigade_name,
			b.office_id,
			os.office_name,
			b.master_employee_id,
			es.employee_name master_employee_name,
			b.is_deleted
	FROM	Settings.Brigade b   
			INNER JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = b.master_employee_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = b.office_id
	WHERE	@and_deleted = 1
			OR	b.is_deleted = 0