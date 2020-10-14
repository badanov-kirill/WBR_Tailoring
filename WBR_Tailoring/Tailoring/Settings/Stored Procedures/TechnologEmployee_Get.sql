CREATE PROCEDURE [Settings].[TechnologEmployee_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	te.employee_id,
			es.employee_name
	FROM	Settings.TechnologEmployee te   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = te.employee_id
