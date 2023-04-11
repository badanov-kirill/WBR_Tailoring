
CREATE PROCEDURE [Reports].[SHKRm_GetAllInfo]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	smai.doc_id,
			dt.doc_type_name,
			s.supplier_name,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			su.su_name,
			smai.qty,
			o.symbol                      okei_symbol,
			smai.stor_unit_residues_qty,
			osu.symbol                    stor_unit_residues_okei_symbol,
			CAST(smai.dt AS DATETIME)     dt,
			smai.employee_id,
			smai.frame_width,
			smai.is_defected,
			sp.proc_name,
			smai.nds,
			smai.gross_mass,
			smai.doc_type_id,
			smai.is_terminal_residues,
			smai.tissue_density,
			smai .fabricator_id,
			f.fabricator_name			
	FROM	History.SHKRawMaterialActualInfo smai   
	        LEFT JOIN Warehouse.SHKRawMaterialActualInfo sm
				ON sm.shkrm_id = smai.shkrm_id
			LEFT JOIN Settings.Fabricators f
				ON f.fabricator_id = smai.fabricator_id
			LEFT JOIN	Documents.DocumentType dt
				ON	dt.doc_type_id = smai.doc_type_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	smai.rmt_id = rmt.rmt_id   
			LEFT JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			LEFT JOIN	Qualifiers.OKEI osu
				ON	osu.okei_id = smai.stor_unit_residues_okei_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			LEFT JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			LEFT JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			LEFT JOIN	RefBook.SpaceUnit su
				ON	su.su_id = smai.su_id   
			LEFT JOIN	History.StoredProcedure sp
				ON	sp.proc_id = smai.proc_id
	WHERE	smai.shkrm_id = @shkrm_id
	ORDER BY
		smai.log_id
	
	SELECT	CAST(smop.dt AS DATETIME) dt,
			sp.place_name,
			zor.zor_name,
			os.office_name,
			smop.employee_id,
			spr.proc_name
	FROM	History.SHKRawMaterialOnPlace smop   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = smop.place_id   
			LEFT JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			LEFT JOIN	History.StoredProcedure spr
				ON	spr.proc_id = smop.proc_id
	WHERE	smop.shkrm_id = @shkrm_id
	ORDER BY
		smop.log_id
	
	SELECT	CAST(sms.dt AS DATETIME) dt,
			smsd.state_name,
			sms.employee_id,
			spr.proc_name
	FROM	History.SHKRawMaterialState sms   
			LEFT JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	History.StoredProcedure spr
				ON	spr.proc_id = sms.proc_id
	WHERE	sms.shkrm_id = @shkrm_id
	ORDER BY
		sms.log_id
	
	SELECT	CAST(smr.dt AS DATETIME)         dt,
			smr.quantity,
			o.symbol                         okei_symbol,
			smr.employee_id,
			smr.operation,
			spr.proc_name,
			c.completing_name,
			spcvc.completing_number,
			ISNULL(pa.sa + pan.sa, s.sa)     sa,
			an.art_name,
			spcv.spcv_name
	FROM	History.SHKRawMaterialReserv smr   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			LEFT JOIN	History.StoredProcedure spr
				ON	spr.proc_id = smr.proc_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			LEFT JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
	WHERE	smr.shkrm_id = @shkrm_id
	ORDER BY
		smr.hshrmr_id
	
	SELECT	s.shipping_id,
			CAST(s.dt AS DATETIME)           dt,
			osrc.office_name                 src_office_name,
			odst.office_name                 dst_office_name,
			CAST(t.dt AS DATETIME)           shk_dt,
			rmt.rmt_name,
			a.art_name,
			su.su_name,
			t.qty,
			o.symbol                         okei_symbol,
			t.stor_unit_residues_qty,
			osu.symbol                       stor_unit_residues_okei_symbol,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = t.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * t.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * t.gross_mass / sma.gross_mass
			END                              amount,
			t.employee_id,
			t.nds,
			t.gross_mass,
			t.complite_employee_id,
			CAST(t.complite_dt AS DATETIME) complite_dt,
			CAST(s.close_dt AS DATETIME)     close_dt
	FROM	Logistics.TTNDetail t   
			INNER JOIN	Logistics.TTN ttn
				ON	ttn.ttn_id = t.ttn_id   
			INNER JOIN	Logistics.Shipping s
				ON	s.shipping_id = ttn.shipping_id   
			INNER JOIN	Settings.OfficeSetting osrc
				ON	osrc.office_id = s.src_office_id   
			INNER JOIN	Settings.OfficeSetting odst
				ON	odst.office_id = ttn.dst_office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	t.rmt_id = rmt.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = t.art_id   
			INNER JOIN	Qualifiers.OKEI osu
				ON	osu.okei_id = t.stor_unit_residues_okei_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = t.okei_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = t.su_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = t.shkrm_id
	WHERE	t.shkrm_id = @shkrm_id
	ORDER BY
		s.shipping_id,
		t.ttnd_id
	
	SELECT	s.shipping_id,
			CAST(s.dt AS DATETIME)     dt,
			osrc.office_name           src_office_name,
			odst.office_name           dst_office_name,
			rmt.rmt_name,
			a.art_name,
			t.divergence_qty           qty,
			o.symbol                   okei_symbol,
			CASE 
			     WHEN sma.stor_unit_residues_okei_id = t.stor_unit_residues_okei_id OR sma.gross_mass = 0 THEN sma.amount * t.stor_unit_residues_qty / sma.stor_unit_residues_qty
			     ELSE sma.amount * t.gross_mass / sma.gross_mass
			END                        amount,
			t.create_employee_id       employee_id,
			t.nds,
			t.gross_mass
	FROM	Logistics.TTNDivergenceAct t   
			INNER JOIN	Logistics.TTN ttn
				ON	ttn.ttn_id = t.ttn_id   
			INNER JOIN	Logistics.Shipping s
				ON	s.shipping_id = ttn.shipping_id   
			INNER JOIN	Settings.OfficeSetting osrc
				ON	osrc.office_id = s.src_office_id   
			INNER JOIN	Settings.OfficeSetting odst
				ON	odst.office_id = ttn.dst_office_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	t.rmt_id = rmt.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = t.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = t.okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = t.shkrm_id
	WHERE	t.shkrm_id = @shkrm_id
	ORDER BY
		s.shipping_id,
		t.ttnda_id
	
	SELECT	mip.mip_id,
			w.workshop_name,
			CAST(mip.create_dt AS DATETIME) create_dt,
			mip.complite_dt,
			oa.x                           sa,
			CAST(mipds.dt AS DATETIME)     dt,
			rmt.rmt_name,
			a.art_name,
			mipds.qty,
			mipds.return_qty,
			o.symbol                       okei_symbol,
			CAST(mipds.return_dt AS DATETIME) return_dt,
			mipds.employee_id,
			mipds.recive_employee_id,
			mipds.return_employee_id,
			oan.x                          nm
	FROM	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = mipds.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			INNER JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = mipds.mip_id   
			LEFT JOIN	Warehouse.Workshop w
				ON	mip.workshop_id = w.workshop_id   
			OUTER APPLY (
			      	SELECT	pa.sa + pan.sa + '(' + an.art_name + ') '
			      	FROM	Warehouse.MaterialInProductionDetailNom mipdn   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = mipdn.pan_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id   
			      			INNER JOIN	Products.Sketch s
			      				ON	s.sketch_id = pa.sketch_id   
			      			INNER JOIN	Products.ArtName an
			      				ON	an.art_name_id = s.art_name_id
			      	WHERE	mipdn.mip_id = mip.mip_id
			      	FOR XML	PATH('')
			      ) oa(x)OUTER APPLY (
			                   	SELECT	CAST(pan2.nm_id AS VARCHAR(10)) + '; '
			                   	FROM	Warehouse.MaterialInProductionDetailNom mipdn2   
			                   			INNER JOIN	Products.ProdArticleNomenclature pan2
			                   				ON	pan2.pan_id = mipdn2.pan_id
			                   	WHERE	mipdn2.mip_id = mip.mip_id
			                   	FOR XML	PATH('')
			                   ) oan(x)
	WHERE	mipds.shkrm_id = @shkrm_id
	ORDER BY
		mip.mip_id,
		mipds.mipds_id
	
	SELECT	CAST(smr.dt AS DATETIME)         dt,
			smr.quantity,
			o.symbol                         okei_symbol,
			smr.employee_id,
			c.completing_name,
			spcvc.completing_number,
			ISNULL(pa.sa + pan.sa, s.sa)     sa,
			an.art_name,
			smr.spcvc_id,
			smr.shkrm_id,
			spcv.spcv_name
	FROM	Warehouse.SHKRawMaterialReserv smr   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			LEFT JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
	WHERE	smr.shkrm_id = @shkrm_id
	
	SELECT	cis.covering_id,
			os.office_name,
			CAST(c.create_dt AS DATETIME) create_dt,
			CAST(c.cost_dt AS DATETIME)     complite_dt,
			oa.x                            sa,
			CAST(cis.dt AS DATETIME)        dt,
			rmt.rmt_name,
			a.art_name,
			cis.qty,
			cis.return_qty,
			o.symbol                        okei_symbol,
			CAST(cis.return_dt AS DATETIME) return_dt,
			cis.employee_id,
			cis.recive_employee_id,
			cis.return_employee_id,
			oan.x                           nm,
			cis.cisr_id
	FROM	Planing.CoveringIssueSHKRm cis   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = cis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smi.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smi.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = cis.okei_id   
			INNER JOIN	Planing.Covering c
				ON	c.covering_id = cis.covering_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id   
			OUTER APPLY (
			      	SELECT	pa.sa + pan.sa + '(' + an.art_name + ') '
			      	FROM	Planing.CoveringDetail cd   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = cd.spcv_id   
			      			INNER JOIN	Products.ProdArticleNomenclature pan
			      				ON	pan.pan_id = spcv.pan_id   
			      			INNER JOIN	Products.ProdArticle pa
			      				ON	pa.pa_id = pan.pa_id   
			      			INNER JOIN	Products.Sketch s
			      				ON	s.sketch_id = pa.sketch_id   
			      			INNER JOIN	Products.ArtName an
			      				ON	an.art_name_id = s.art_name_id
			      	WHERE	cd.covering_id = cis.covering_id
			      	FOR XML	PATH('')
			      ) oa(x)OUTER APPLY (
			                   	SELECT	CAST(pan2.nm_id AS VARCHAR(10)) + '; '
			                   	FROM	Planing.CoveringDetail cd2   
			                   			INNER JOIN	Planing.SketchPlanColorVariant spcv2
			                   				ON	spcv2.spcv_id = cd2.spcv_id   
			                   			INNER JOIN	Products.ProdArticleNomenclature pan2
			                   				ON	pan2.pan_id = spcv2.pan_id
			                   	WHERE	cd2.covering_id = cis.covering_id
			                   	FOR XML	PATH('')
			                   ) oan(x)
	WHERE	cis.shkrm_id = @shkrm_id
	ORDER BY
		cis.covering_id,
		cis.cisr_id
	
	SELECT	sma.stor_unit_residues_qty,
			sma.amount,
			sma.amount / sma.stor_unit_residues_qty price,
			sma.employee_id,
			sp.proc_name,
			CAST(sma.dt AS DATETIME) dt
	FROM	History.SHKRawMaterialAmount sma   
			INNER JOIN	History.StoredProcedure sp
				ON	sp.proc_id = sma.proc_id
	WHERE	sma.shkrm_id = @shkrm_id
	ORDER BY
		sma.log_id
	
	SELECT	rme.rme_id,
			rme.doc_id,
			rme.doc_type_id,
			CAST(rme.create_dt AS DATETIME) create_dt,
			rme.create_employee_id,
			CAST(rme.return_dt AS DATETIME) return_dt,
			rme.return_employee_id,
			rme.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			s.supplier_name,
			rme.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			rme.frame_width,
			rme.is_defected,
			rmt2.rmt_name                  need_rmt_name,
			cc2.color_name                 need_color_name,
			rme.need_qty,
			o2.symbol                      need_okei_symbol,
			sma.amount * rme.stor_unit_residues_qty / sma.stor_unit_residues_qty amount
	FROM	Material.RawMaterialExchange rme   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rme.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rme.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rme.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rme.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rme.stor_unit_residues_okei_id   
			INNER JOIN	Material.RawMaterialType rmt2
				ON	rmt2.rmt_id = rme.need_rmt_id   
			INNER JOIN	Material.ClothColor cc2
				ON	cc2.color_id = rme.need_color_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = rme.need_okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = rme.shkrm_id
	WHERE	rme.shkrm_id = @shkrm_id
	
	SELECT	rmedc.rmed_id,
			rmedc.rme_id,
			rmedc.shkrm_id,
			rmedc.rmt_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			rmedc.stor_unit_residues_qty     qty,
			o.symbol                         okei_symbol,
			rmedc.frame_width,
			rmedc.is_defected,
			sma.amount * rmedc.stor_unit_residues_qty / sma.stor_unit_residues_qty amount
	FROM	Material.RawMaterialExchangeDetailChange rmedc   
			INNER JOIN	Material.RawMaterialExchange rme
				ON	rme.rme_id = rmedc.rme_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rmedc.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rmedc.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rmedc.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmedc.stor_unit_residues_okei_id
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = rme.shkrm_id
	WHERE	rme.shkrm_id = @shkrm_id

	SELECT	rme.rmr_id,
			rme.doc_id,
			rme.doc_type_id,
			CAST(rme.create_dt AS DATETIME) create_dt,
			rme.create_employee_id,
			CAST(rme.return_dt AS DATETIME) return_dt,
			rme.return_employee_id,
			rme.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			s.supplier_name,
			rme.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			rme.frame_width,
			rme.is_defected,
			sma.amount * rme.stor_unit_residues_qty / sma.stor_unit_residues_qty amount
	FROM	Material.RawMaterialReturn rme   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rme.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rme.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rme.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rme.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rme.stor_unit_residues_okei_id    
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = rme.shkrm_id
	WHERE	rme.shkrm_id = @shkrm_id
	
	SELECT	rme.rmicd_id,
			rme.rmic_id,		
			CAST(rmic.create_dt AS DATETIME) create_dt,
			CAST(rmic.close_dt AS DATETIME) return_dt,
			rmic.close_employee_id,
			rme.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			s.supplier_name,
			rme.stor_unit_residues_qty     qty,
			o.symbol                       okei_symbol,
			rme.frame_width,
			rme.is_defected,
			rme.amount amount
	FROM	Material.RawMaterialInvoiceCorrectionDetail rme
			INNER JOIN Material.RawMaterialInvoiceCorrection rmic ON rmic.rmic_id = rme.rmic_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = rme.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = rme.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = rme.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = rme.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rme.stor_unit_residues_okei_id    
	WHERE	rme.shkrm_id = @shkrm_id