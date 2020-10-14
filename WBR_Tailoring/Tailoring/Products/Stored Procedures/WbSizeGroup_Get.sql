CREATE PROCEDURE [Products].[WbSizeGroup_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	wsg.wb_size_group_id,
			wsg.wb_size_group_description
	FROM	Products.WbSizeGroup wsg