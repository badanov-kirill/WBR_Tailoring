CREATE PROCEDURE [SyncFinance].[ServiceIncome_GetChanges]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @doc_tab TABLE(doc_id INT)
	
	INSERT INTO @doc_tab
		(
			doc_id
		)
	SELECT	si.doc_id
	FROM	SyncFinance.ServiceIncome si
	
	SELECT	si.doc_id id,
			si.doc_dt,
			si.supplier_id,
			si.suppliercontract_code,
			si.ttn_name         income_doc_num,
			si.ttn_dt           income_doc_dt,
			si.invoice_name     sf_num,
			si.invoice_dt       sf_dt,
			si.employee_id,
			si.is_deleted,
			si.currency_id,
			si.hash_string,
			si.hash_dt,
			si.rv--,
			--si.ots_id
	FROM	SyncFinance.ServiceIncome si   
			INNER JOIN	@doc_tab dt
				ON	dt.doc_id = si.doc_id
	
	SELECT	sd.doc_id,
			sd.rmt_id,
			sd.nds,
			sd.amount_with_nds,
			rmt.rmt_name
	FROM	SyncFinance.ServiceIncomeDetail sd   
			INNER JOIN	@doc_tab dt
				ON	dt.doc_id = sd.doc_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = sd.rmt_id
GO


GO