
CREATE PROCEDURE [Material].[RawMaterialIncome_GetDetail]
	@doc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @doc_type_id TINYINT = 1
	
	DECLARE @tab_invoice AS TABLE 
	        (rmi_id INT, invoice_name VARCHAR(30), invoice_dt DATE, dt DATETIME2(0), employee_id INT, ttn_name VARCHAR(30), ttn_dt DATE, set_file BIT, file_ext_name VARCHAR(20))	
	
	INSERT @tab_invoice
	  (
	    rmi_id,
	    invoice_name,
	    invoice_dt,
	    dt,
	    employee_id,
	    ttn_name, 
	    ttn_dt,
	    set_file,
	    file_ext_name
	  )
	SELECT	rm_inv.rmi_id,
			rm_inv.invoice_name,
			rm_inv.invoice_dt,
			rm_inv.dt,
			rm_inv.employee_id,
			rm_inv.ttn_name, 
			rm_inv.ttn_dt,
			CASE 
			     WHEN rm_inv.set_file_dt IS NOT NULL THEN 1
			     ELSE 0
			END set_file,
			fe.file_ext_name
	FROM	Material.RawMaterialInvoice rm_inv
	LEFT JOIN RefBook.FileExt fe ON fe.file_ext_id = rm_inv.file_ext_id
	WHERE	rm_inv.doc_id = @doc_id
			AND	rm_inv.doc_type_id = @doc_type_id
			AND	rm_inv.is_deleted = 0
	
	SELECT	CAST(di.create_dt AS DATETIME) create_dt,
			di.create_employee_id,
			rmi.employee_id,
			rmi.supplier_id,
			rmi.is_deleted,
			rmi.payment_comment,
			rmi.plan_sum,
			CAST(rmi.goods_dt AS DATETIME) goods_dt,
			CAST(rmi.supply_dt AS DATETIME) supply_dt,
			rmi.comment,
			rmi.suppliercontract_id,
			CAST(rmi.dt AS DATETIME)     dt,
			CAST(CAST(rmi.rv AS BIGINT) AS VARCHAR(20)) rv_bigint,
			CAST(rmi.scan_load_dt AS DATETIME) scan_load_dt,
			rmis.rmis_name,
			rmis.rmis_id,
			s.supplier_name,
			'(' + ISNULL(c.currency_name_shot, ' ') + ') ' + sc.suppliercontract_name suppliercontract_name,
			ots.ots_id,
			CAST(ots.doc_dt AS DATETIME) ots_doc_dt,
			es_ots.employee_name ots_employee_name,
			stopt.type_of_payment_name ots_type_of_payment_name,
			ots.comment ots_comment,
			c_ots.currency_name_shot ots_currency_name_shot,
			ots.amount,
			rmi.company_id,
			rmi.fabricator_id,
			f.fabricator_name
	FROM	Documents.DocumentID di   
			INNER JOIN	Material.RawMaterialIncome rmi
				ON	di.doc_id = rmi.doc_id
				AND	di.doc_type_id = rmi.doc_type_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = rmi.supplier_id   
			INNER JOIN	Suppliers.SupplierContract sc
			LEFT JOIN RefBook.Currency c ON c.currency_id = sc.currency_id
				ON	sc.suppliercontract_id = rmi.suppliercontract_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id
			LEFT JOIN Material.OrderToSupplier ots 
			LEFT JOIN	Suppliers.SupplierContract sc_ots
				ON	sc_ots.suppliercontract_erp_id = ots.suppliercontract_erp_id   
			LEFT JOIN	Settings.EmployeeSetting es_ots
				ON	es_ots.employee_id = ots.employee_id   
			LEFT JOIN	Material.SpecificationTypeOfPayment stopt
				ON	stopt.type_of_payment_id = ots.type_of_payment_id   
			LEFT JOIN	RefBook.Currency c_ots
				ON	c_ots.currency_id = sc_ots.currency_id
				ON ots.ots_id = rmi.ots_id
			LEFT JOIN Settings.Fabricators f 
				ON f.fabricator_id = rmi.fabricator_id
				
	WHERE	di.doc_id = @doc_id
			AND	di.doc_type_id = @doc_type_id
	
	SELECT	ssu.shksu_id,
			su.su_name,
			ssu.quantity,
			CAST(ssu.create_dt AS DATETIME) create_dt,
			ssu.create_employee_id,
			CAST(ssu.close_dt AS DATETIME) close_dt,
			ssu.close_employee_id
	FROM	Warehouse.SHKSpaceUnit ssu   
			INNER  JOIN	RefBook.SpaceUnit su
				ON	su.su_id = ssu.su_id
	WHERE	ssu.doc_id = @doc_id
			AND	ssu.doc_type_id = @doc_type_id				
	
	SELECT	rmie.rmie_id,
			rmie.amount,
			rmie.create_employee_id,
			CAST(rmie.create_dt AS DATETIME) create_dt,
			rmie.employee_id,
			CAST(rmie.dt AS DATETIME) dt,
			rmie.descript
	FROM	Material.RawMaterialIncomeExpense rmie
	WHERE	rmie.doc_id = @doc_id
			AND	rmie.doc_type_id = @doc_type_id
			AND	rmie.is_deleted = 0
	
	SELECT	ti.rmi_id,
			ti.invoice_name,
			CAST(ti.invoice_dt AS DATETIME) invoice_dt,
			CAST(ti.dt AS DATETIME)     dt,
			ti.employee_id,
			ti.ttn_name,
			CAST(ti.ttn_dt AS DATETIME) ttn_dt,
			ti.set_file,
			ti.file_ext_name
	FROM	@tab_invoice                ti
	
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
	FROM	@tab_invoice ti   
			INNER JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmi_id = ti.rmi_id   
			INNER JOIN	Material.RawMaterialInvoiceItem rmii
				ON	rmii.rmii_id = rmid.rmii_id   
			LEFT JOIN Material.RawMaterialInvoiceItemCode rmiic
				ON rmiic.rmiic_id = rmid.rmiic_id
			INNER JOIN	RefBook.Countries c
				ON	c.country_id = rmid.country_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmid.okei_id   
			LEFT JOIN	Material.GTD g
				ON	g.gtd_id = rmid.gtd_id
	ORDER BY
		rmid.rmid_id,
		rmii.item_name
	
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
			rmid.is_defected,
			smsd.state_name,
			sp.place_name,
			os.office_name,
			ISNULL(smai.stor_unit_residues_qty, 0) - ISNULL(oa_res.res_qty, 0) free_qty
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
			LEFT JOIN Warehouse.SHKRawMaterialState sms
			INNER JOIN Warehouse.SHKRawMaterialStateDict smsd
				ON smsd.state_id = sms.state_id
				ON sms.shkrm_id = rmid.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialOnPlace smop
			INNER JOIN Warehouse.StoragePlace sp
			INNER JOIN Warehouse.ZoneOfResponse zor
			INNER JOIN Settings.OfficeSetting os
				ON os.office_id = zor.office_id
				ON zor.zor_id = sp.zor_id
				ON sp.place_id = smop.place_id
				ON smop.shkrm_id = rmid.shkrm_id
			LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
				ON smai.shkrm_id = rmid.shkrm_id
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) res_qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      ) oa_res
	WHERE	rmid.doc_id = @doc_id
			AND	rmid.doc_type_id = @doc_type_id
			AND	rmid.is_deleted = 0
	ORDER BY
		rmid.shkrm_id
	
	SELECT	rmio.rmo_id,
			rmio.rmio_id,
			rmio.employee_id,
			CAST(rmo.create_dt AS DATETIME) create_dt,
			CAST(rmo.supply_dt AS DATETIME) supply_dt,
			rmo.comment
	FROM	Material.RawMaterialIncomeOrder rmio   
			INNER JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = rmio.rmo_id
	WHERE	rmio.doc_id = @doc_id
			AND	rmio.doc_type_id = @doc_type_id
		
	
GO