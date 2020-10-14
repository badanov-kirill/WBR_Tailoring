CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJobInSalary_GetBySTSJ]
	@stsj_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sp.salary_year,
			sp.salary_month,
			stsjis.cnt,
			stsjis.amount,
			CAST(stsjis.dt AS DATETIME) dt,
			es.employee_name
	FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis   
			INNER JOIN	Salary.SalaryPeriod sp
				ON	sp.salary_period_id = stsjis.salary_period_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = stsjis.employee_id
	WHERE	stsjis.stsj_id = @stsj_id
