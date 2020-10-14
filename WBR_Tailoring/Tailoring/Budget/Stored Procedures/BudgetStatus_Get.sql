CREATE PROCEDURE [Budget].[BudgetStatus_Get]
AS
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	SELECT	bs.bs_id,
			bs.bs_name
	FROM	Budget.BudgetStatus bs