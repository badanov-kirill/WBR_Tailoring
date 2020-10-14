CREATE PROCEDURE [Material].[RawMaterialIncomeDetail_GetByIDForDO]
	@rmi_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmiv.invoice_name,
			CAST(rmiv.invoice_dt AS DATETIME) invoice_dt,
			rmt.rmt_name,
			rmt.rmt_astra_id,
			rmid.okei_id okei_id,
			o.symbol              okei_symbol,
			SUM(rmird.amount  )     sum_amount,
			SUM(rmid.quantity * (rmird.amount / rmid.amount_with_nds) ) sum_qty,
			FORMAT(SUM(rmird.amount /(100+rmid.nds) * 100 ) / SUM(rmid.quantity * (rmird.amount / rmid.amount_with_nds) ), '0.00') price
	FROM	Material.RawMaterialInvoice rmiv   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = rmiv.rmi_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id 
			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird   
			INNER JOIN	Material.RawMaterialIncomeDetail rminvd   
			  
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rminvd.rmt_id
				ON	rminvd.rmid_id = rmird.rmid_id
				ON	rmird.rm_invd_id = rmid.rmid_id
	WHERE	rmiv.rmi_id = @rmi_id
	GROUP BY
		rmiv.invoice_name,
		rmiv.invoice_dt,
		rmt.rmt_name,
		rmt.rmt_astra_id,
		rmid.okei_id,
		o.symbol