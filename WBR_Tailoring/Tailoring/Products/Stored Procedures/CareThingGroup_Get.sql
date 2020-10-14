CREATE PROCEDURE [Products].[CareThingGroup_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ctg.ctg_id,
			ctg.ctg_name
	FROM	Products.CareThingGroup ctg