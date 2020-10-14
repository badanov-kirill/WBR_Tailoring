CREATE PROCEDURE [Settings].[StringValue_Get]
	@code CHAR(3)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	sv.svalue,
			CAST(sv.dt AS DATETIME)     dt,
			sv.employee_id
	FROM	Settings.StringValue        sv
	WHERE	sv.code = @code
