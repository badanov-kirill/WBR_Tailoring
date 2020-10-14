CREATE PROCEDURE [Manufactory].[CuttingActualEmployee_Get]
	@ca_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cae.employee_id
	FROM	Manufactory.CuttingActualEmployee cae
	WHERE	cae.ca_id = @ca_id