CREATE PROCEDURE [Synchro].[DownloadUPD_DocDetail_Get]
	@dud_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ddt.esf_id,
			ddt.edo_pos_id,
			duin.item_name     item_name,
			ddt.edo_okei_code,
			ddt.okei_name,
			ddt.edo_quantity,
			ddt.edo_price,
			duia.item_name     item_article,
			duic.item_name     item_code,
			duis.item_name     item_spec,
			ddt.edo_amount_nds,
			ddt.edo_amount_with_nds,
			ddt.edo_amount_without_nds,
			ddt.edo_vat,
			g.gtd_cod,
			ddt.edo_country_id,
			c.country_name
	FROM	Synchro.DownloadUPD_DocDetail ddt   
			LEFT JOIN	Synchro.DownloadUPD_Item duin
				ON	duin.dui_id = ddt.dui_id_item_name   
			LEFT JOIN	Synchro.DownloadUPD_Item duia
				ON	duia.dui_id = ddt.dui_id_item_article   
			LEFT JOIN	Synchro.DownloadUPD_Item duic
				ON	duic.dui_id = ddt.dui_id_item_code   
			LEFT JOIN	Synchro.DownloadUPD_Item duis
				ON	duis.dui_id = ddt.dui_id_item_spec   
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = ddt.gtd_id
			LEFT JOIN RefBook.Countries c
				ON ddt.edo_country_id = c.country_id
	WHERE	ddt.dud_id = @dud_id
	ORDER BY
		ddt.esf_id,
		ddt.edo_pos_id