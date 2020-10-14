CREATE PROCEDURE [Material].[RawMaterialIncomeDetail_FindByInvoiceData]
	@supplier_id INT,
	@doc_num VARCHAR(30),
	@doc_dt DATE
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmi.doc_id,
			CAST(rmi.dt AS DATETIME)     doc_dt,
			rmt.rmt_name,
			rmt.rmt_astra_id,
			rminvd.stor_unit_residues_okei_id okei_id,
			SUM(rmird.amount)            sum_amount,
			SUM(rminvd.stor_unit_residues_qty) sum_qty,
			SUM(rmird.amount) / SUM(rminvd.stor_unit_residues_qty) price
	FROM	Material.RawMaterialIncome rmi   
			INNER JOIN	Material.RawMaterialInvoice rmiv
				ON	rmiv.doc_id = rmi.doc_id
				AND	rmiv.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = rmiv.rmi_id   
			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird   
			INNER JOIN	Material.RawMaterialIncomeDetail rminvd   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rminvd.rmt_id
				ON	rminvd.rmid_id = rmird.rmid_id
				ON	rmird.rm_invd_id = rmid.rmid_id
	WHERE	rmi.supplier_id = @supplier_id
			AND	rmiv.invoice_dt = @doc_dt
			AND	rmiv.invoice_name = @doc_num
			AND	rmi.rmis_id = 7
	GROUP BY
		rmi.doc_id,
		rmi.dt,
		rmt.rmt_name,
		rmt.rmt_astra_id,
		rminvd.stor_unit_residues_okei_id