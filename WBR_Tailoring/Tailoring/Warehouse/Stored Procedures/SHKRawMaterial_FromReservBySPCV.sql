CREATE PROCEDURE [Warehouse].[SHKRawMaterial_FromReservBySPCV]
	@spcv_id INT,
	@rmt_id INT = NULL,
	@color_id INT = NULL,
	@art_name VARCHAR(12) = NULL,
	@frame_width SMALLINT = NULL,
	@shkrm_id INT = NULL,
	@color_name VARCHAR(20) = NULL,
	@with_terminal_residues BIT = 0,
	@fabricator_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @sew_office_id INT
	DECLARE @main_office_id INT

	
	--SELECT	@main_office_id = os.office_id
	--FROM	Settings.OfficeSetting os
	--WHERE	os.is_main_wh = 1
	
	SELECT	@sew_office_id = spcv.sew_office_id
	FROM	Planing.SketchPlanColorVariant spcv
	WHERE	spcv.spcv_id = @spcv_id
	
	SELECT	TOP(2000) smai.shkrm_id,
			rmt.rmt_name,
			a.art_name,
			cc.color_name,
			smai.stor_unit_residues_qty,
			o.symbol     stor_unit_residues_okei_symbol,
			s.supplier_name,
			sma.amount / sma.stor_unit_residues_qty price_su,
			oa.qty       reserv_qty,
			smai.rmt_id,
			smai.frame_width,
			sp.place_name,
			zor.zor_name,
			os.office_name,
			oa_or.x office_reserv,
			rmtp.rmtp_id,
			smlsd.state_name logic_state_name,
			smai.fabricator_id,
			f.fabricator_name  
	FROM	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Warehouse.SHKRawMaterialOnPlace smop
				ON	smop.shkrm_id = smai.shkrm_id   
			INNER JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = smop.place_id   
			INNER JOIN	Warehouse.ZoneOfResponse zor
				ON	zor.zor_id = sp.zor_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = zor.office_id   
			INNER JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.stor_unit_residues_okei_id   
			INNER JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = smai.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id
			INNER JOIN Settings.Fabricators f
				ON	f.fabricator_id = smai.fabricator_id  
			LEFT JOIN Material.RawMaterialTypePhoto rmtp
				ON rmtp.art_id = smai.art_id 
				AND rmtp.rmt_id = smai.rmt_id 
				AND rmtp.color_id = smai.color_id 
				AND rmtp.supplier_id = sc.supplier_id 
				AND ISNULL(smai.frame_width, 0) =ISNULL(rmtp.frame_width, 0)  
			LEFT JOIN Warehouse.SHKRawMaterialLogicState smls
			INNER JOIN Warehouse.SHKRawMaterialLogicStateDict smlsd
				ON smlsd.state_id = smls.state_id
				ON smls.shkrm_id = smai.shkrm_id 
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      )      oa
			OUTER APPLY (
				SELECT v.office_name + '; '
				FROM (
				SELECT DISTINCT os2.office_name 
				FROM Warehouse.SHKRawMaterialReserv smr
				INNER JOIN Planing.SketchPlanColorVariantCompleting spcvc ON spcvc.spcvc_id = smr.spcvc_id
				INNER JOIN Planing.SketchPlanColorVariant spcv ON spcv.spcv_id = spcvc.spcv_id
				INNER JOIN Settings.OfficeSetting os2 ON os2.office_id = spcv.sew_office_id
				WHERE smr.shkrm_id = smai.shkrm_id
				) v
				FOR XML PATH('')
			) oa_or(x)
	WHERE	(@rmt_id IS NULL OR smai.rmt_id = @rmt_id)
			AND	(@color_id IS NULL OR smai.color_id = @color_id)
			AND	sms.state_id IN (3)
			AND	(@art_name IS NULL OR a.art_name LIKE '%' + @art_name + '%')
			AND	(@frame_width IS NULL OR smai.frame_width = @frame_width)
			AND	(@shkrm_id IS NULL OR smai.shkrm_id = @shkrm_id)
			AND	(@color_name IS NULL OR cc.color_name LIKE '%' + @color_name + '%')
			AND	(zor.office_id = @sew_office_id OR zor.office_id IN (100,-2) )--@main_office_id)
			AND smai.stor_unit_residues_qty > ISNULL(oa.qty, 0)
			AND (smai.is_terminal_residues = 0 OR @with_terminal_residues = 1)
		    AND	(smai.fabricator_id = @fabricator_id)
	ORDER BY
		CASE 
		     WHEN zor.office_id = @sew_office_id THEN 0
		     ELSE 1
		END,
		cc.color_name,
		smai.qty - oa.qty DESC