CREATE PROCEDURE [Budget].[BudgetClothStatus_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	bcs.bcs_id,
			bcs.bcs_name
	FROM	Budget.BudgetClothStatus bcs