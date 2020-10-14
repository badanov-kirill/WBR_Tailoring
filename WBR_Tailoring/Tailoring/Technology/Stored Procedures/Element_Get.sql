CREATE PROCEDURE [Technology].[Element_Get]
	@is_deleted BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	e.element_id,
			e.element_name,
			e.dt,
			e.employee_id,
			e.is_deleted
	FROM	Technology.Element e
	WHERE	@is_deleted IS NULL
			OR	e.is_deleted = @is_deleted
	ORDER BY e.element_name