CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrection_GetByID]
	@rmic_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmic.rmic_id,
			rmic.rmi_id,
			rmic.base_invoice_name,
			CAST(rmic.base_invoice_dt AS DATETIME) base_invoice_dt,
			rmic.buch_num,
			CAST(rmic.create_dt AS DATETIME) create_dt,
			es.employee_name       create_employee_name,
			rmic.dt,
			escl.employee_name     close_employee_name,
			CAST(rmic.close_dt AS DATETIME) close_dt,
			rmic.comment,
			rmic.amount_invoice,
			rmic.amount_shk,
			rmic.rmict_id,
			rmicom.supplier_id,
			sc.suppliercontract_erp_id
	FROM	Material.RawMaterialInvoiceCorrection rmic   
			INNER JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = rmic.rmi_id   
			INNER JOIN	Material.RawMaterialIncome rmicom
				ON	rmicom.doc_id = rmi.doc_id
				AND	rmicom.doc_type_id = rmi.doc_type_id  
			INNER JOIN Suppliers.SupplierContract sc
				ON sc.suppliercontract_id = rmicom.suppliercontract_id 
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = rmic.create_employee_id   
			LEFT JOIN	Settings.EmployeeSetting escl
				ON	escl.employee_id = rmic.close_employee_id
	WHERE	rmic.rmic_id = @rmic_id
	
	
	SELECT	rmid.rmid_id,
			rmid.rmii_id,
			rmii.item_name,
			rmid.price,
			rmid.base_quantity               quantity,
			rmid.base_amount_with_nds        amount_with_nds,
			rmid.base_amount_nds             amount_nds,
			rmid.base_amount_without_nds     amount_without_nds,
			rmid.nds,
			rmid.okei_id,
			o.fullname                       okei_fullname,
			o.symbol                         okei_symbol,
			rmid.country_id,
			c.country_name,
			rmid.gtd_id,
			g.gtd_cod,
			rmid.base_item_number,
			rmid.return_quantity,
			rmid.item_number,
			ROUND(rmid.base_amount_with_nds * (rmid.return_quantity / rmid.base_quantity), 2) return_amount,
			rmid.rmt_id,
			rmt.rmt_name
	FROM	Material.RawMaterialInvoiceCorrectionInvoiceDetail rmid   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			INNER JOIN	RefBook.Countries c
				ON	c.country_id = rmid.country_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id 
			INNER JOIN Material.RawMaterialType rmt
				ON rmt.rmt_id = rmid.rmt_id  
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = rmid.gtd_id
	WHERE	rmid.rmic_id = @rmic_id
	ORDER BY
		rmid.item_number
	
	SELECT	rmid.rmid_id,
			rmid.shkrm_id,
			rmid.frame_width,
			rmid.rmt_id,
			rmt.rmt_name,
			rmid.art_id,
			a.art_name,
			rmid.color_id,
			cc.color_name,
			rmid.su_id,
			su.su_name,
			rmid.okei_id,
			o.fullname     okei_name,
			rmid.qty,
			rmid.stor_unit_residues_okei_id,
			rmid.stor_unit_residues_qty,
			CASE 
			     WHEN rmid.stor_unit_residues_qty = 0 THEN 0
			     ELSE rmid.amount / rmid.stor_unit_residues_qty
			END            price,
			rmid.amount,
			rmid.nds,
			rmid.dt,
			rmid.employee_id,
			rmid.shksu_id,
			rmid.is_defected
	FROM	Material.RawMaterialInvoiceCorrectionDetail rmid   
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
	WHERE	rmid.rmic_id = @rmic_id