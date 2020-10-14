 CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_GetToCost]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	DECLARE @tab_expense AS TABLE 
	        (rmie_id INT, descript VARCHAR(300), amount DECIMAL(19, 8))
	
	DECLARE @tab_invoice AS TABLE 
	        (
	        	rmi_id INT,
	        	invoice_name VARCHAR(30),
	        	invoice_dt DATE,
	        	item_number SMALLINT,
	        	rmid_id INT,
	        	rmii_id INT,
	        	item_name VARCHAR(200),
	        	quantity DECIMAL(9, 3),
	        	amount DECIMAL(19, 8),
	        	okei_id INT,
	        	okei_name VARCHAR(50)
	        )	
	
	INSERT @tab_expense
	  (
	    rmie_id,
	    descript,
	    amount
	  )
	SELECT	rmie.rmie_id,
			rmie.descript,
			rmie.amount
	FROM	Material.RawMaterialIncomeExpense rmie
	WHERE	rmie.doc_id = @doc_id
			AND	rmie.doc_type_id = @doc_type_id
			AND	rmie.is_deleted = 0		
	
	INSERT @tab_invoice
	  (
	    rmi_id,
	    invoice_name,
	    invoice_dt,
	    item_number,
	    rmid_id,
	    rmii_id,
	    item_name,
	    quantity,
	    amount,
	    okei_id,
	    okei_name
	  )
	SELECT	rm_inv.rmi_id,
			rm_inv.invoice_name,
			rm_inv.invoice_dt,
			rmid.item_number,
			rmid.rmid_id,
			rmid.rmii_id,
			rmii.item_name,
			rmid.quantity,
			rmid.amount_with_nds     amount,
			rmid.okei_id,
			o.fullname               okei_name
	FROM	Material.RawMaterialInvoice rm_inv   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = rm_inv.rmi_id   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id
	WHERE	rm_inv.doc_id = @doc_id
			AND	rm_inv.doc_type_id = @doc_type_id
			AND	rm_inv.is_deleted = 0
	
	SELECT	rmid.rmid_id,
			rmid.frame_width,
			rmid.shkrm_id,
			rmid.rmt_id,
			rmt.rmt_name,
			rmid.art_id,
			a.art_name,
			rmid.color_id,
			cc.color_name,
			rmid.su_id,
			su.su_name,
			rmid.okei_id,
			o.fullname okei_name,
			rmid.qty,
			rmid.amount,
			rmid.is_defected
	FROM	Material.RawMaterialIncomeDetail rmid   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmid.rmt_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = rmid.su_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmid.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rmid.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id
	WHERE	rmid.doc_id = @doc_id
			AND	rmid.doc_type_id = @doc_type_id
			AND	rmid.is_deleted = 0
			AND NOT EXISTS(
			              	SELECT	1
			              	FROM	Material.RawMaterialReturn rmr
			              	WHERE	rmr.shkrm_id = rmid.shkrm_id
			              )
	ORDER BY
		rmid.shkrm_id	 
	
	SELECT	te.rmie_id,
			te.descript,
			te.amount
	FROM	@tab_expense te	
	
	SELECT	rmid.shkrm_id,
			rmierd.rmid_id,
			rmierd.rmie_id,
			rmierd.amount
	FROM	@tab_expense te   
			INNER JOIN	Material.RawMaterialIncomeExpenseRelationDetail rmierd
				ON	rmierd.rmie_id = te.rmie_id   
			INNER JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.rmid_id = rmierd.rmid_id
	ORDER BY
		rmid.shkrm_id,
		rmierd.rmie_id
	
	SELECT	ti.rmi_id,
			ti.invoice_name,
			CAST(ti.invoice_dt AS DATETIME) invoice_dt,
			ti.item_number,
			ti.rmid_id rm_invd_id,
			ti.rmii_id,
			ti.item_name,
			ti.quantity,
			ti.amount,
			ti.okei_id,
			ti.okei_name
	FROM	@tab_invoice ti
	ORDER BY
		ti.rmid_id,
		ti.item_name
	
	SELECT	rmid.shkrm_id,
			rmird.rmid_id,
			rmird.rm_invd_id,
			rmird.amount
	FROM	@tab_invoice ti   
			INNER JOIN	Material.RawMaterialInvoiceRelationDetail rmird
				ON	rmird.rm_invd_id = ti.rmid_id   
			INNER JOIN	Material.RawMaterialIncomeDetail rmid
				ON	rmid.rmid_id = rmird.rmid_id
	ORDER BY
		rmid.shkrm_id,
		rmird.rm_invd_id
		
	SELECT	CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint
	FROM	Material.RawMaterialIncome rmi
	WHERE	rmi.doc_id = @doc_id
			AND	@doc_type_id = @doc_type_id
GO