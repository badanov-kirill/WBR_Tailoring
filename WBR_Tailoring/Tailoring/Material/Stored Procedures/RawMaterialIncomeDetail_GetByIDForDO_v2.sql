CREATE PROCEDURE [Material].[RawMaterialIncomeDetail_GetByIDForDO_v2]
	@rmi_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmic.ots_id,
			rmiv.invoice_name,
			CAST(rmiv.invoice_dt AS DATETIME) invoice_dt,
			oa.rmt_name,
			oa.rmt_astra_id,
			rmid.okei_id          okei_id,
			o.symbol              okei_symbol,
			rmid.nds,
			SUM(rmird.amount)     sum_amount,
			SUM(rmid.quantity * (rmird.amount / rmid.amount_with_nds)) sum_qty,
			ROUND(SUM(rmird.amount / (100 + rmid.nds) * 100) / SUM(rmid.quantity * (rmird.amount / rmid.amount_with_nds)), 2) price,
			ROUND(SUM(rmird.amount) / SUM(rmid.quantity * (rmird.amount / rmid.amount_with_nds)), 2) price_with_vat
	INTO	#t
	FROM	Material.RawMaterialInvoice rmiv   
			INNER JOIN	Material.RawMaterialIncome rmic
				ON	rmic.doc_id = rmiv.doc_id
				AND	rmic.doc_type_id = rmiv.doc_type_id   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = rmiv.rmi_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id   
			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird   
			INNER JOIN	Material.RawMaterialIncomeDetail rminvd   
				ON	rminvd.rmid_id = rmird.rmid_id
				ON	rmird.rm_invd_id = rmid.rmid_id
			OUTER APPLY (
			      	SELECT	TOP(1) rmt.rmt_astra_id, rmt0.rmt_name
			      	FROM	Material.RawMaterialTypeVariant rmt
			      	INNER JOIN Material.RawMaterialType rmt0 ON rmt0.rmt_id = rmt.rmt_id		
			      	WHERE	rmt.rmt_id = rminvd.rmt_id
			      				AND	rmt.art_id = rminvd.art_id
			      				AND	(rmt.frame_width = rminvd.frame_width
			      				OR	(rmt.frame_width IS NULL
			      				AND	rminvd.frame_width IS NULL))
			      			AND	rmt.rmt_astra_id IS NOT NULL
			      )                     oa
	WHERE	rmiv.rmi_id = @rmi_id
	GROUP BY
		rmic.ots_id,
		rmiv.invoice_name,
		rmiv.invoice_dt,
		oa.rmt_name,
		oa.rmt_astra_id,
		rmid.okei_id,
		o.symbol,
		rmid.nds
	
	SELECT	t.invoice_name,
			t.invoice_dt,
			t.rmt_name,
			t.rmt_astra_id,
			t.okei_id          okei_id,
			t.okei_symbol,
			t.nds,
			t.sum_amount,
			t.sum_qty,
			t.price,
			t.price_with_vat
	from	#t t
	
	SELECT	ots.ots_id,
			CAST(ots.doc_dt AS DATETIME)     doc_dt,
			otsmd.nomenclature_name,
			otsmd.mat_id,
			o.symbol                         okei_symbol,
			otsmd.amount                     sum_amount,
			otsmd.qty                        sum_qty,
			otsmd.price,
			otsmd.nds,
			otsmd.price_with_vat
	FROM	Material.OrderToSupplier ots   
			INNER JOIN	Material.OrderToSupplierMaterialDetail otsmd
				ON	otsmd.ots_id = ots.ots_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = otsmd.okei_id
	WHERE	EXISTS(
	     		SELECT	1
	     		FROM	#t t
	     		WHERE	t.ots_id = ots.ots_id
	     				AND	t.rmt_astra_id = otsmd.mat_id
	     	)
	
	SELECT	stc.stc_id,
			CAST(stc.doc_dt AS DATETIME)     doc_dt,
			stcmd.nomenclature_name,
			stcmd.mat_id,
			o.symbol                         okei_symbol,
			stcmd.amount                     sum_amount,
			stcmd.qty                        sum_qty,
			stcmd.price,
			stcmd.nds,
			stcmd.price_with_vat
	FROM	Material.SpecificationToContract stc   
			INNER JOIN	Material.OrderToSupplier ots
				ON	ots.stc_id = stc.stc_id   
			INNER JOIN	Material.SpecificationToContractMaterialDetail stcmd
				ON	stcmd.stc_id = stc.stc_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = stcmd.okei_id
	WHERE	EXISTS(
	     		SELECT	1
	     		FROM	#t t
	     		WHERE	t.ots_id = ots.ots_id
	     				AND	t.rmt_astra_id = stcmd.mat_id
	     	)