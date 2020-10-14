CREATE PROCEDURE [Technology].[DrawingComplexity_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	dc.dc_id,
			dc.dc_name
	FROM	Technology.DrawingComplexity dc
