CREATE PROCEDURE [Warehouse].[SHKRawMaterialActualInfo_Get_v2]
	@rmt_xml XML = NULL,
	@state_xml XML,
	@state_id INT = NULL
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
	
	SELECT	rmt.rmt_id,
			rmt.rmt_name,
			cc.color_name,
			a.art_name,
			smai.stor_unit_residues_qty,
			o2.symbol                    stor_unit_residues_okei_symbol,
			smai.frame_width,
			smai.shkrm_id,
			sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty amount,
			sp.place_name,
			os.office_name,
			smsd.state_name,
			ISNULL(oar.qty, 0)           reserv_qty,
			smai.stor_unit_residues_qty - ISNULL(oar.qty, 0) free_qty,
			CAST(sms.dt AS DATETIME)     state_dt,
			CAST(sma.final_dt AS DATETIME) final_dt,
			CASE 
			     WHEN smai.doc_type_id = 1 THEN smai.doc_id
			     ELSE 0
			END                          doc_id,
			smai.doc_type_id,
			smai.is_terminal_residues is_terminal_residues,
			s.supplier_name,
			smai.tissue_density,
			smlsd.state_name logic_state_name,
			f.fabricator_name
	FROM	Warehouse.SHKRawMaterialActualInfo smai 
			INNER JOIN Settings.Fabricators f
				ON f.fabricator_id = smai.fabricator_id
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
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      )                      oar
			LEFT JOIN Warehouse.SHKRawMaterialLogicState smls
			INNER JOIN Warehouse.SHKRawMaterialLogicStateDict smlsd
				ON smlsd.state_id = smls.state_id
				ON smls.shkrm_id = smai.shkrm_id
	WHERE (@state_id IS NULL OR smls.state_id = @state_id)
