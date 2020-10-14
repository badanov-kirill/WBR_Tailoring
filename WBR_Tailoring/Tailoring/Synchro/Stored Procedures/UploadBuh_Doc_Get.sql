CREATE PROCEDURE [Synchro].[UploadBuh_Doc_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_tab TABLE(doc_id INT, upload_doc_type_id TINYINT)
	
	INSERT INTO @doc_tab
		(
			doc_id,
			upload_doc_type_id
		)
	SELECT	ubd.doc_id,
			ubd.upload_doc_type_id
	FROM	Synchro.UploadBuh_Doc ubd
	
	SELECT	ubd.doc_id,
			ubd.upload_doc_type_id,
			ubd.suppliercontract_code,
			ubd.supplier_id,
			ubd.is_deleted,
			CAST(ubd.rv AS BIGINT)           rv_bigint,
			ubd.office_id,
			CAST(ubd.doc_dt AS DATETIME)     doc_dt,
			ubd.currency_id
	FROM	@doc_tab dt   
			INNER JOIN	Synchro.UploadBuh_Doc ubd
				ON	ubd.doc_id = dt.doc_id
				AND	ubd.upload_doc_type_id = dt.upload_doc_type_id
		
	SELECT	ubdid.doc_id,
			ubdid.upload_doc_type_id,
			ubdid.invoice_name,
			CAST(ubdid.invoice_dt AS DATETIME) invoice_dt,
			ubdid.rmt_id,
			ubdid.nds,
			ubdid.amount,
			ubdid.ttn_name, 
			CAST(ubdid.ttn_dt AS DATETIME) ttn_dt,
			ubdid.amount_cur
	FROM	@doc_tab dt   
			INNER JOIN	Synchro.UploadBuh_DocInvoiceDetail ubdid
				ON	ubdid.doc_id = dt.doc_id
				AND	ubdid.upload_doc_type_id = dt.upload_doc_type_id
	UNION ALL
	SELECT	ubdd.doc_id,
			ubdd.upload_doc_type_id,
			NULL,
			NULL,
			ubdd.rmt_id,
			ubdd.nds,
			ubdd.amount,
			NULL,
			NULL,
			0
	FROM	@doc_tab dt   
			INNER JOIN	Synchro.UploadBuh_DocDetail ubdd
				ON	ubdd.doc_id = dt.doc_id
				AND	ubdd.upload_doc_type_id = dt.upload_doc_type_id
GO

GRANT EXECUTE
    ON OBJECT::[Synchro].[UploadBuh_Doc_Get] TO [WILDBERRIES\USR1CV8]
    AS [dbo];
GO

