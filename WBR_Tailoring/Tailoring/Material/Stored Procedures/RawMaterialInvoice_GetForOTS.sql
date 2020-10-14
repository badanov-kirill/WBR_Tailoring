CREATE PROCEDURE [Material].[RawMaterialInvoice_GetForOTS]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmii.item_name,
			ISNULL(rmiic.item_code, '')     item_code,
			ROUND(rmid.amount_with_nds / rmid.quantity, 2) price,
			o.symbol                        okei_symbol,
			rmid.quantity,
			CAST(rmid.nds AS VARCHAR(10)) + '%' nds,
			v.rmt_astra_id                  mat_id
	FROM	Material.RawMaterialIncome rmi   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id   
			INNER JOIN	Material.RawMaterialInvoice rmiv
				ON	rmiv.doc_id = rmi.doc_id
				AND	rmiv.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = rmiv.rmi_id   
			LEFT JOIN	Material.RawMaterialInvoiceItemCode rmiic
				ON	rmiic.rmiic_id = rmid.rmiic_id   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id   
			OUTER APPLY (
			      	SELECT	TOP(1) ISNULL(rmt.rmt_astra_id, rmtb.rmt_astra_id) rmt_astra_id
			      	FROM	Material.RawMaterialInvoiceRelationDetail rmird   
			      			INNER JOIN	Material.RawMaterialIncomeDetail rminvd   
			      			INNER JOIN	Material.RawMaterialType rmtb
			      				ON	rmtb.rmt_id = rminvd.rmt_id   
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
			      		CASE 
			      		     WHEN rmt.rmt_astra_id IS NOT NULL THEN 0
			      		     ELSE 1
			      		END ASC,
			      		rminvd.rmid_id
			      )                         v
	WHERE	rmi.doc_id = @doc_id