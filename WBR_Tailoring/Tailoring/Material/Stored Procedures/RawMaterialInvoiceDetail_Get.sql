CREATE PROCEDURE [Material].[RawMaterialInvoiceDetail_Get]
	@rmi_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmid.rmid_id,
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
			rmid.item_number
	FROM	Material.RawMaterialInvoiceDetail rmid   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			INNER JOIN	RefBook.Countries c
				ON	c.country_id = rmid.country_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id   
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = rmid.gtd_id
	WHERE	rmid.rmi_id = @rmi_id
	ORDER BY
		rmid.item_number