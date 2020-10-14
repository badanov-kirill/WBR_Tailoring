CREATE PROCEDURE [History].[SketchStatus_Get]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(ss.dt AS DATETIME)     dt,
			ssd.ss_name,
			ssd.ss_short_name,
			es.employee_name
	FROM	History.SketchStatus ss   
			INNER JOIN	Products.SketchStatus ssd
				ON	ssd.ss_id = ss.ss_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = ss.employee_id
	WHERE	ss.sketch_id = @sketch_id
	ORDER BY
		ss.hss_id                    ASC
