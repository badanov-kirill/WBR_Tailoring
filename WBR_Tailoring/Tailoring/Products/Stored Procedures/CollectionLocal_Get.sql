CREATE PROCEDURE [Products].[CollectionLocal_Get]
	@year SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cl.season_model_year,
			cl.season_local_id,
			sl.season_local_name,
			cl.brand_id,
			b.brand_name,
			CAST(cl.close_dt AS DATETIME) close_dt,
			cl.close_employee_id,
			es.employee_name close_employee_name
	FROM	Products.CollectionLocal cl   
			INNER JOIN	Products.SeasonLocal sl
				ON	sl.season_local_id = cl.season_local_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = cl.brand_id
			LEFT JOIN Settings.EmployeeSetting es
				ON es.employee_id = cl.close_employee_id
	WHERE	@year IS NULL
			OR	cl.season_model_year = @year
	ORDER BY
		cl.season_model_year,
		cl.season_local_id,
		cl.brand_id