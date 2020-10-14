CREATE PROCEDURE [Synchro].[Upload_RMI_BuhVas_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	urbv.rm_inv_id                invoice_id,
			CAST(urbv.dt AS DATETIME)     invoice_dt,
			CAST(urbv.rv AS BIGINT)       rv_bigint
	INTO	#t
	FROM	Synchro.Upload_RMI_BuhVas urbv
	
	SELECT	t.invoice_id,
			CAST(sc.buh_uid AS VARCHAR(36)) sup_contr_uid,
			rmiv.invoice_name,
			cast(rmiv.invoice_dt AS DATETIME) invoice_dt,
			t.rv_bigint,
			rmiv.doc_id
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
	
	SELECT	t.invoice_id          invoice_id,
			rminvd.rmt_id,
			rmid.nds,
			rminvd.stor_unit_residues_okei_id         okei_id,
			o.fullname            okei_name,
			o.symbol              symbol,
			SUM(rmird.amount)     amount,
			SUM(rminvd.stor_unit_residues_qty * (rmird.amount / rminvd.amount)) qty,
			--ROUND(SUM(rmird.amount / (100 + rmid.nds) * 100) / SUM(rminvd.qty * (rmird.amount / rminvd.amount)), 2) price,
			ROUND(SUM(rmid.amount_nds * (rmird.amount / rmid.amount_with_nds)), 2) amount_vat,
			ROUND(SUM(rmird.amount) / SUM(rminvd.stor_unit_residues_qty * (rmird.amount / rminvd.amount)), 2) price,
			MAX(g.gtd_cod)        gtd,
			MAX(c.cod3b)          cod3b
	FROM	#t t   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = t.invoice_id   
			   
			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird   
			INNER JOIN	Material.RawMaterialIncomeDetail rminvd
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rminvd.stor_unit_residues_okei_id
				ON	rminvd.rmid_id = rmird.rmid_id
				ON	rmird.rm_invd_id = rmid.rmid_id   
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = rmid.gtd_id   
			LEFT JOIN	RefBook.Countries c
				ON	c.country_id = rmid.country_id
	GROUP BY
		t.invoice_id,
		rminvd.rmt_id,
		rmid.nds,
		rminvd.stor_unit_residues_okei_id,
		o.fullname,
		o.symbol,
		rmid.nds
	ORDER BY MIN(rmid.item_number)
