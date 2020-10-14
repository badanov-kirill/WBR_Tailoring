CREATE PROCEDURE [Manufactory].[Operation_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	o.operation_id,
			o.operation_name,
			o.operation_description
	FROM	Manufactory.Operation o