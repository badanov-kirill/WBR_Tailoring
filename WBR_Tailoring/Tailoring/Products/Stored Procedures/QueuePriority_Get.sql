CREATE PROCEDURE [Products].[QueuePriority_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	qp.qp_id,
			qp.qp_name
	FROM	Products.QueuePriority qp
