CREATE PROCEDURE [Synchro].[UploadInvoiceToDO_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	uitd.invoice_id,
			uitd.supplier_id,
			uitd.invoice_name,
			CAST(uitd.invoice_dt AS DATETIME) invoice_dt,
			uitd.amount_with_nds,
			uitd.num_ots,
			CAST(uitd.rv AS BIGINT) rv_bigint
	INTO	#t
	FROM	Synchro.UploadInvoiceToDO uitd
	
	SELECT	t.invoice_id,
			t.supplier_id,
			sc.suppliercontract_code,
			sc.suppliercontract_erp_id,
			t.invoice_name,
			t.invoice_dt,
			t.amount_with_nds,
			t.num_ots,
			t.rv_bigint,
			CASE 
			     WHEN rmiv.set_file_dt IS NOT NULL THEN 1
			     ELSE 0
			END set_file,
			fe.file_ext_name
	FROM	#t t   
			INNER JOIN	Material.RawMaterialInvoice rmiv   
			LEFT JOIN	RefBook.FileExt fe
				ON	fe.file_ext_id = rmiv.file_ext_id
				ON	rmiv.rmi_id = t.invoice_id   
			INNER JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = rmiv.doc_id
				AND	rmi.doc_type_id = rmiv.doc_type_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rmi.suppliercontract_id  
	
	SELECT	t.invoice_id                invoice_id,
			rmii.item_name              nomenclature_name,
			rmiic.item_code             nomenclature_code,
			oa.rmt_astra_id             mat_id,
			n.nds_do_id                 vat_id,
			rmid.quantity               qty,
			rmid.price                  price,
			rmid.amount_with_nds        amount,
			rmid.amount_without_nds     amount_without_vat,
			rmid.amount_nds             amount_vat,
			rmid.okei_id
	FROM	#t t   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = t.invoice_id   
			INNER JOIN	Material.RawMaterialInvoice rmiv
				ON	rmiv.rmi_id = rmid.rmi_id   
			LEFT JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			LEFT JOIN	Material.RawMaterialInvoiceItemCode rmiic
				ON	rmiic.rmiic_id = rmid.rmiic_id   
			INNER JOIN	RefBook.NDS n
				ON	n.nds = rmid.nds  
			OUTER APPLY (
			      	SELECT	TOP(1) isnull(rmt.rmt_astra_id, rmtb.rmt_astra_id) rmt_astra_id
			      	FROM	Material.RawMaterialInvoiceRelationDetail rmird   
			      			INNER JOIN	Material.RawMaterialIncomeDetail rminvd
			      			INNER JOIN Material.RawMaterialType rmtb	
								ON rmtb.rmt_id = rminvd.rmt_id   
			      			LEFT JOIN	Material.RawMaterialTypeVariant rmt
			      				ON	rmt.rmt_id = rminvd.rmt_id
			      				AND	rmt.art_id = rminvd.art_id
			      				AND	(rmt.frame_width = rminvd.frame_width
			      				OR	(rmt.frame_width IS NULL
			      				AND	rminvd.frame_width IS NULL))
			      				ON	rminvd.rmid_id = rmird.rmid_id
			      	WHERE	rmird.rm_invd_id = rmid.rmid_id
			      			AND	rmird.doc_id = rmiv.doc_id
			      			AND	rmird.doc_type_id = rmiv.doc_type_id
			      	ORDER BY
			      			CASE WHEN rmt.rmt_astra_id  IS NOT NULL THEN 0 ELSE 1 END ASC,
			      			rminvd.rmid_id
			      )                     oa
	
