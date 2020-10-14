CREATE PROCEDURE [Settings].[BrigadeEmployeeDate_GetByEmployee]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(bed.begin_dt AS DATETIME) begin_dt,
			bed.brigade_id,
			b.brigade_name,
			CAST(bed.dt AS DATETIME) dt
	FROM	Settings.BrigadeEmployeeDate bed   
			LEFT JOIN	Settings.Brigade b
				ON	b.brigade_id = bed.brigade_id
	WHERE	bed.employee_id = @employee_id
	ORDER BY
		bed.begin_dt