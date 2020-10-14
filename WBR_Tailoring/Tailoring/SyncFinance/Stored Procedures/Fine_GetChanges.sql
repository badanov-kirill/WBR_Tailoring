CREATE PROCEDURE [SyncFinance].[Fine_GetChanges]
AS
	SET NOCOUNT ON
	
	SELECT	f.id,
			f.imprest_employee_id,
			f.cash_sum,
			f.currency_id,
			f.comment,
			f.is_deleted,
			f.edit_employee_id,
			f.approve_employee_id,
			f.cfo_id,
			f.imprest_cfo_id,
			f.source_type_id,
			f.source_id,
			f.context,
			f.rv
	FROM	SyncFinance.Fine f
GO

GRANT EXECUTE
    ON OBJECT::[SyncFinance].[Fine_GetChanges] TO [WILDBERRIES\FinanceServices]
    AS [dbo];
GO