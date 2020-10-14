CREATE PROCEDURE [Technology].[TechAction_Get]
	@is_deleted BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ta.ta_id,
			ta.ta_name,
			ta.dt,
			ta.employee_id,
			ta.is_deleted
	FROM	Technology.TechAction ta
	WHERE	@is_deleted IS NULL
			OR	ta.is_deleted = @is_deleted