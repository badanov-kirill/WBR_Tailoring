CREATE PROCEDURE [Planing].[SketchPrePlanStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spps.spps_id,
			spps.spps_name
	FROM	Planing.SketchPrePlanStatus spps