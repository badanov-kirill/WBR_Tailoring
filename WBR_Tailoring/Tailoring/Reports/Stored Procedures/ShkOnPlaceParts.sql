CREATE PROCEDURE [Reports].[ShkOnPlaceParts]
	@rmt_id INT = NULL,
	@art_name VARCHAR(12) = NULL,
	@supplier_id INT = NULL,
	@color_id INT = NULL,
	@frame_width SMALLINT = NULL,
	@photo BIT = NULL,
	@state_id INT = NULL,
	@rmt_xml XML = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @rm_tab TABLE(rmt_id INT PRIMARY KEY CLUSTERED)
	
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
	
	SELECT  smai.rmt_id,	
			rmt.rmt_name,
			cc.color_name,
			s.supplier_name,
			o2.symbol     stor_unit_residues_okei_symbol,
			s.supplier_id,
			cc.color_id,
			smai.doc_id,
			CAST(ISNULL(rmi.goods_dt, smai.dt) AS DATETIME) dt,
			SUM(sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty) amount,
			SUM(sma.amount * (smai.stor_unit_residues_qty - ISNULL(oa_res.resrv_qtu, 0)) / sma.stor_unit_residues_qty) amount_free,
			SUM(smai.stor_unit_residues_qty) qty,
			SUM(smai.stor_unit_residues_qty - ISNULL(oa_res.resrv_qtu, 0)) free_qty
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			LEFT JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = smai.doc_id
				AND	rmi.doc_type_id = smai.doc_type_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = smai.stor_unit_residues_okei_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	smai.shkrm_id = sms.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Material.RawMaterialTypePhoto rmtp
				ON	rmtp.art_id = smai.art_id
				AND	rmtp.rmt_id = smai.rmt_id
				AND	rmtp.color_id = smai.color_id
				AND	rmtp.supplier_id = sc.supplier_id
				AND	ISNULL(smai.frame_width, 0) = ISNULL(rmtp.frame_width, 0)   
			LEFT JOIN	Warehouse.SHKRawMaterialLogicState smls   
			INNER JOIN	Warehouse.SHKRawMaterialLogicStateDict smlsd
				ON	smlsd.state_id = smls.state_id
				ON	smls.shkrm_id = smai.shkrm_id  
			INNER JOIN	@rm_tab rmtb
				ON	rmtb.rmt_id = smai.rmt_id 
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) resrv_qtu
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      )       oa_res
	WHERE	(@supplier_id IS NULL OR s.supplier_id = @supplier_id)
			AND	(@rmt_id IS NULL OR smai.rmt_id = @rmt_id)
			AND	(@art_name IS NULL OR a.art_name = @art_name)
			AND	(@color_id IS NULL OR smai.color_id = @color_id)
			AND	(@frame_width IS NULL OR smai.frame_width = @frame_width)
			AND	(@photo IS NULL OR (@photo = 1 AND rmtp.rmtp_id IS NOT NULL) OR (@photo = 0 AND rmtp.rmtp_id IS NULL))
			AND	((@state_id IS NULL AND (smls.state_id IS NULL OR smls.state_id NOT IN (2,3,4))) OR smls.state_id = @state_id)
			AND	sms.state_id = 3
	GROUP BY
		smai.rmt_id,
		rmt.rmt_name,
		cc.color_name,
		s.supplier_name,
		ISNULL(rmi.goods_dt, smai.dt),
		o2.symbol,
		s.supplier_id,
		cc.color_id,
		smai.doc_id
	ORDER BY
		SUM(sma.amount * (smai.stor_unit_residues_qty - ISNULL(oa_res.resrv_qtu, 0)) / sma.stor_unit_residues_qty) DESC