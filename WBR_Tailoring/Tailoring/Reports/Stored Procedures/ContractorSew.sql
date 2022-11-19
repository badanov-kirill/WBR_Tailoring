CREATE PROCEDURE [Reports].[ContractorSew]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	s.sketch_id,
			sj.subject_name,
			an.art_name,
			pa.sa + pan.sa        sa,
			pan.nm_id,
			os.office_name        sew_office_name,
			ISNULL(spcv.corrected_qty, spcv.qty) qty,
			oa_c.actual_count     cut_actual_count,
			spcv.pre_cost,
			spcv.pre_cost /
			CASE 
			     WHEN spcv.corrected_qty > 0 THEN spcv.corrected_qty
			     WHEN spcv.qty > 0 THEN spcv.qty
			     ELSE NULL
			END                   pre_price,
			spcv.spcv_id,
			oa_sketch_cost_job.cost_job,
			oa_spent.spent_amount
	FROM	Planing.SketchPlanColorVariant spcv   
			JOIN	Settings.OfficeSetting os
				ON	os.office_id = spcv.sew_office_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			OUTER APPLY (
			      	SELECT	SUM(ca.actual_count) actual_count,
			      			MAX(c.closing_dt) closing_dt
			      	FROM	Manufactory.Cutting c   
			      			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			      				ON	spcvt.spcvts_id = c.spcvts_id   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = c.cutting_id
			      	WHERE	spcvt.spcv_id = spcv.spcv_id
			      ) oa_c
			OUTER APPLY (
	      			SELECT	SUM(stsjc.cost_per_hour * sts.operation_time / 3600) cost_job
	      			FROM	Products.TechnologicalSequence sts   
	      					INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJobCost stsjc
	      						ON	stsjc.discharge_id = sts.discharge_id
	      						AND	stsjc.office_id = spcv.sew_office_id
	      			WHERE	sts.sketch_id = s.sketch_id
	      					AND	s.technology_dt IS NOT NULL
				  )                       oa_sketch_cost_job
			OUTER APPLY (
			      	SELECT	SUM(sma.amount * (cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) 
			      	      	spent_amount
			      	FROM	Planing.CoveringDetail cd   
			      			INNER JOIN	Planing.CoveringIssueSHKRm cis
			      				ON	cis.covering_id = cd.covering_id   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = cis.shkrm_id
			      	WHERE	cd.spcv_id = spcv.spcv_id
			      ) oa_spent 
	WHERE	EXISTS (
	     		SELECT	TOP(1) 1
	     		FROM	Manufactory.ContractorSewCount csc   
	     				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	     					ON	spcvt.spcvts_id = csc.spcvts_id
	     		WHERE	spcvt.spcv_id = spcv.spcv_id
	     	)
