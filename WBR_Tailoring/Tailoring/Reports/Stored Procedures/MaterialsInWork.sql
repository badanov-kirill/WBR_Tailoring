CREATE PROCEDURE [Reports].[MaterialsInWork]
AS

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME = GETDATE()
	
	SELECT	DATEADD(second, -1, CAST(d.dt AS DATETIME)) moment_dt,
			oa.shkrm_id,
			oa.rmt_name,
			oa.qty,
			oa.material_cost,
			CAST(oa.covering_dt AS DATETIME ) covering_dt,
			CAST(oa.fist_package_dt AS DATETIME )fist_package_dt
	FROM	dbo.Days d   
			OUTER APPLY (
			      	SELECT	cis.shkrm_id,
			      			rmt.rmt_name,
			      			FORMAT(cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0), '0.00') qty,
			      			FORMAT(sma.amount * (cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty, '0.00') material_cost,
			      			cis.dt covering_dt,
			      			v.fist_package_dt
			      	FROM	Planing.CoveringIssueSHKRm cis   
			      			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
			      				ON	smi.shkrm_id = cis.shkrm_id   
			      			INNER JOIN	Material.RawMaterialType rmt
			      				ON	rmt.rmt_id = smi.rmt_id   
			      			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = smi.shkrm_id   
			      			INNER JOIN	(SELECT	cd.covering_id,
			      			    	     	 		MIN(spcv.fist_package_dt) fist_package_dt
			      			    	     	 FROM	Planing.CoveringDetail cd   
			      			    	     	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      			    	     	 			ON	spcv.spcv_id = cd.spcv_id
			      			    	     	 GROUP BY
			      			    	     	 	cd.covering_id)v
			      				ON	v.covering_id = cis.covering_id
			      	WHERE	cis.dt < CAST(d.dt AS DATETIME)
			      			AND	cis.dt > DATEADD(month, -12, @dt)--'20200301'
			      			AND	(v.fist_package_dt IS NULL OR v.fist_package_dt > CAST(d.dt AS DATETIME))
			      			AND	cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0) != 0
			      			AND	EXISTS(
			      			   		SELECT	1
			      			   		FROM	Planing.CoveringDetail cd   
			      			   				INNER JOIN	Planing.SketchPlanColorVariant spcv
			      			   					ON	spcv.spcv_id = cd.spcv_id
			      			   		WHERE	cd.covering_id = cis.covering_id
			      			   				AND	(spcv.fist_package_dt IS NULL OR spcv.fist_package_dt > CAST(d.dt AS DATETIME))
			      			   	)
			      )oa
	WHERE	DAY(d.dt) = 1
			AND	d.dt >= DATEADD(month, -12, @dt)--'20201002'
			AND	d.dt <= @dt
