CREATE PROCEDURE [Planing].[CompletingStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	cs.cs_id,
			cs.cs_name
	FROM	Planing.CompletingStatus cs