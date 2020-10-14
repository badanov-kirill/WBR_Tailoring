CREATE PROCEDURE [Warehouse].[SHKRawMaterialReserv_Get]
	@rmt_xml XML = NULL,
	@state_xml XML
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @rm_tab TABLE(rmt_id INT PRIMARY KEY CLUSTERED)
	DECLARE @state_tab TABLE(state_id INT PRIMARY KEY CLUSTERED)
	
	IF @rmt_xml IS NOT NULL
	BEGIN
	    INSERT INTO @rm_tab
	    	(
	    		rmt_id
	    	)
	    SELECT	ml.value('@id', 'int')
	    FROM	@rmt_xml.nodes('root/det')x(ml)
	END
	ELSE
	BEGIN
	    INSERT INTO @rm_tab
	    	(
	    		rmt_id
	    	)
	    SELECT	rmt.rmt_id
	    FROM	Material.RawMaterialType rmt
	END
	
	INSERT INTO @state_tab
		(
			state_id
		)
	SELECT	ml.value('@id', 'int')
	FROM	@state_xml.nodes('root/det')x(ml)
	
	SELECT	cmp.completing_name + cast(spcvc.completing_number AS VARCHAR(10)) completing,
			ISNULL(pa.sa + pan.sa, sk.sa) sa,
			an.art_name sketch_art_name,
			rmt.rmt_id,
			rmt.rmt_name,
			cc.color_name,
			a.art_name,
			smai.stor_unit_residues_qty,
			o2.symbol                     stor_unit_residues_okei_symbol,
			smai.frame_width,
			smai.shkrm_id,
			sma.amount * smr.quantity / sma.stor_unit_residues_qty amount,
			sp.place_name,
			os.office_name,
			smsd.state_name,
			smr.quantity                  reserv_qty,
			CAST(sms.dt AS DATETIME)      state_dt,
			CAST(sma.final_dt AS DATETIME) final_dt,
			CASE 
			     WHEN smai.doc_type_id = 1 THEN smai.doc_id
			     ELSE 0
			END                           doc_id,
			smai.doc_type_id,
			smai.is_terminal_residues     is_terminal_residues,
			s.supplier_name,
			smai.tissue_density,
			cvs.cvs_name
	FROM	Warehouse.SHKRawMaterialReserv smr   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id   
			INNER JOIN	Material.Completing cmp
				ON	cmp.completing_id = spcvc.completing_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id  
			INNER JOIN Planing.ColorVariantStatus cvs
				ON cvs.cvs_id = spcv.cvs_id 
			LEFT JOIN Products.ProdArticleNomenclature pan
			INNER JOIN Products.ProdArticle pa
				ON pa.pa_id = pan.pa_id
				ON pan.pan_id = spcv.pan_id
			INNER JOIN	Planing.SketchPlan spl
				ON	spl.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch sk
				ON	sk.sketch_id = spl.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = sk.art_name_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = smai.stor_unit_residues_okei_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	RefBook.SpaceUnit su
				ON	su.su_id = smai.su_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
			INNER JOIN	Warehouse.StoragePlace sp   
			INNER JOIN	Warehouse.ZoneOfResponse zor   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id
				ON	zor.zor_id = sp.zor_id
				ON	sp.place_id = smop.place_id
				ON	smop.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	smai.shkrm_id = sms.shkrm_id   
			INNER JOIN	@rm_tab rmtb
				ON	rmtb.rmt_id = smai.rmt_id   
			INNER JOIN	@state_tab stt
				ON	stt.state_id = sms.state_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id    