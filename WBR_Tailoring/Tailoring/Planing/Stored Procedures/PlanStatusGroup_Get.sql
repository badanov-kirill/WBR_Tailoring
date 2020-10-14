CREATE PROCEDURE [Planing].[PlanStatusGroup_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	psg.psg_id,
			psg.psg_name
	FROM	Planing.PlanStatusGroup psg