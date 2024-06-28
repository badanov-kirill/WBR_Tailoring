CREATE PROCEDURE [Manufactory].[OrderChestnyZnak_GetForSignature]
@fabricator_id INT = null
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ocz.ocz_id,
			CAST(ocz.create_dt AS DATETIME) create_dt,
			CAST(ocz.dt AS DATETIME)         dt,
			ocz.employee_id,
			ocz.covering_id,
			ocz.fabricator_id
	FROM	Manufactory.OrderChestnyZnak     ocz
	WHERE	ocz.is_deleted = 0
			AND	ocz.sign_dt IS NULL
			AND (@fabricator_id IS NULL OR ocz.fabricator_id = @fabricator_id)
