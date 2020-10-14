CREATE PROCEDURE [Material].[RawMaterialInvoiceDetail_GetByDocID]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	SELECT	ti.rmi_id,
			ti.invoice_name,
			rmid.rmid_id,
			rmid.rmii_id,
			rmii.item_name,
			rmid.price,
			rmid.quantity,
			rmid.amount_with_nds,
			rmid.amount_nds,
			rmid.amount_without_nds,
			rmid.nds,
			rmid.okei_id,
			o.fullname     okei_fullname,
			o.symbol       okei_symbol,
			rmid.country_id,
			c.country_name,
			rmid.gtd_id,
			g.gtd_cod,
			rmid.item_number,
			rmid.amount_cur_with_nds,
			rmiic.item_code
	FROM	Material.RawMaterialInvoice ti   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = ti.rmi_id   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			LEFT JOIN	Material.RawMaterialInvoiceItemCode rmiic
				ON	rmiic.rmiic_id = rmid.rmiic_id   
			INNER JOIN	RefBook.Countries c
				ON	c.country_id = rmid.country_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id   
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = rmid.gtd_id
	WHERE	ti.doc_id = @doc_id
			AND	ti.doc_type_id = @doc_type_id
	ORDER BY
		rmid.rmid_id,
		rmii.item_name