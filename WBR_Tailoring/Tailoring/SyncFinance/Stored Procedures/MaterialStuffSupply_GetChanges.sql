CREATE PROCEDURE [SyncFinance].[MaterialStuffSupply_GetChanges]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @doc_tab TABLE(doc_id INT)
	
	INSERT INTO @doc_tab
		(
			doc_id
		)
	SELECT	mss.doc_id
	FROM	SyncFinance.MaterialStuffSupply mss
	
	SELECT	mss.doc_id id,
			mss.doc_dt,
			mss.supplier_id,
			mss.suppliercontract_code,
			mss.ttn_name         income_doc_num,
			mss.ttn_dt           income_doc_dt,
			mss.invoice_name     sf_num,
			mss.invoice_dt       sf_dt,
			mss.employee_id,
			mss.is_deleted,
			mss.currency_id,
			mss.hash_string,
			mss.hash_dt,
			mss.rv,
			mss.mol_sr_id,
			mss.comment--,
			--mss.ots_id
	FROM	SyncFinance.MaterialStuffSupply mss   
			INNER JOIN	@doc_tab dt
				ON	dt.doc_id = mss.doc_id
	
	SELECT	sd.doc_id,
			sd.nds,
			sd.amount_with_nds,
			CAST(sd.stuff_shk_id AS VARCHAR(10)) stuff_shk,
			sd.stuff_model_id,
			sd.manufactured_number,
			sd.okei_id
	FROM	SyncFinance.MaterialStuffSupplyDetail sd   
			INNER JOIN	@doc_tab dt
				ON	dt.doc_id = sd.doc_id   

GO


GO