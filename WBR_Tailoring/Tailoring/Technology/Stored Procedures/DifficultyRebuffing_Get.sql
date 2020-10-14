CREATE PROCEDURE [Technology].[DifficultyRebuffing_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	dr.dr_id,
			dr.dr_name
	FROM	Technology.DifficultyRebuffing dr
