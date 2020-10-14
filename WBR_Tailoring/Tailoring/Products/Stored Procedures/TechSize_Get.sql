CREATE PROCEDURE [Products].[TechSize_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ts.ts_id,
			ts.ts_name
	FROM	Products.TechSize ts
	ORDER BY
		ts.visible_queue,
		ts.ts_name