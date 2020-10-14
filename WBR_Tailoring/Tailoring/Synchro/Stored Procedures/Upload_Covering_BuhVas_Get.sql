CREATE PROCEDURE [Synchro].[Upload_Covering_BuhVas_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @t TABLE (covering_id INT, dt DATETIME, rv_bigint BIGINT)
	
	INSERT INTO @t
		(
			covering_id,
			dt,
			rv_bigint
		)
	SELECT	ucbv.covering_id,
			CAST(ucbv.dt AS DATETIME)     dt,
			CAST(ucbv.rv AS BIGINT)       rv_bigint
	FROM	Synchro.Upload_Covering_BuhVas ucbv
	
	SELECT	t.covering_id,
			t.dt,
			t.rv_bigint,
			c.office_id,
			o.buh_vas_uid office_uid,
			CAST(ISNULL(c.cost_dt, t.dt) AS DATETIME) cost_dt 
	FROM	@t t
	INNER JOIN Planing.Covering c ON c.covering_id = t.covering_id
	INNER JOIN Settings.OfficeSetting o ON o.office_id = c.office_id
	
	SELECT	t.covering_id,
			cd.spcv_id,
			pa.sketch_id,
			pa.sa + pan.sa     sa,			
			oa_ac.actual_count - ISNULL(oa_cwo.cut_write_off, 0) actual_count,
			pan.price_ru
	FROM	@t t   
			INNER JOIN	Planing.CoveringDetail cd
				ON	cd.covering_id = t.covering_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			OUTER APPLY (
			      	SELECT	ISNULL(SUM(ca.actual_count), 0) actual_count,
			      			ISNULL(SUM(ca.actual_count * cut.perimeter * cut.cutting_tariff), 0) cutting_cost
			      	FROM	Planing.SketchPlanColorVariantTS spcvt   
			      			INNER JOIN	Manufactory.Cutting cut
			      				ON	cut.spcvts_id = spcvt.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_ac 
	
	OUTER APPLY (
	      	SELECT	COUNT(1) cut_write_off
	      	FROM	Planing.SketchPlanColorVariantTS spcvt   
	      			INNER JOIN	Manufactory.Cutting cut
	      				ON	cut.spcvts_id = spcvt.spcvts_id   
	      			INNER JOIN	Manufactory.ProductUnicCode puc
	      				ON	puc.cutting_id = cut.cutting_id
	      	WHERE	spcvt.spcv_id = spcv.spcv_id
	      			AND	puc.operation_id = 12
	      )                    oa_cwo
	WHERE	s.is_deleted = 0
	
	SELECT	t.covering_id,
			spcvc.spcv_id,
			cr.shkrm_id,
			rmt.rmt_id,
			cr.qty,
			sp.sketch_id
	FROM	@t t   
			INNER JOIN	Planing.CoveringReserv cr
				ON	cr.covering_id = t.covering_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = cr.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = cr.okei_id
	
	
	SELECT	t.covering_id,
			cis.shkrm_id,
			rmt.rmt_id,
			o2.okei_id,
			o2.fullname     okei_fullname,
			o2.symbol       okei_symbol,
			cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0) spent_qty
	FROM	@t t   
			INNER JOIN	Planing.CoveringIssueSHKRm cis
				ON	cis.covering_id = t.covering_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = cis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = cis.stor_unit_residues_okei_id   
			
