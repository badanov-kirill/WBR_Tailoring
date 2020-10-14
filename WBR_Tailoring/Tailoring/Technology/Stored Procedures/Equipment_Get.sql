CREATE PROCEDURE [Technology].[Equipment_Get]
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	e.equipment_id,
			e.equipment_name,
			e.dt,
			e.employee_id,
			e.is_deleted
	FROM	Technology.Equipment e
	WHERE	@is_deleted IS NULL
			OR	e.is_deleted = @is_deleted
	ORDER BY e.equipment_name