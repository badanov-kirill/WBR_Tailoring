CREATE PROCEDURE [Manufactory].[CuttingActual_Get]
	@cutting_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ca.ca_id,
			ca.actual_count,
			CAST(ca.dt AS DATETIME)       dt,
			ca.employee_id
	FROM	Manufactory.CuttingActual     ca
	WHERE	ca.cutting_id = @cutting_id