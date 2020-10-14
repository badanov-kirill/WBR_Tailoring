CREATE PROCEDURE [Warehouse].[MaterialInSketch_GetDoc]
	@dt_start DATETIME2(0),
	@dt_finish DATETIME2(0)
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	misd.misd_id,
			CAST(misd.create_dt AS DATETIME) create_dt,
			misd.employee_id,
			misd.office_id,
			os.office_name,
			oa.doc_amount
	FROM	Warehouse.MaterialInSketchDoc misd   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = misd.office_id   
			OUTER APPLY (
			      	SELECT	SUM(sma.amount * (mis.stor_unit_residues_qty - ISNULL(mis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) 
			      	      	doc_amount
			      	FROM	Warehouse.MaterialInSketch mis   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	mis.shkrm_id = sma.shkrm_id
			      	WHERE	mis.misd_id = misd.misd_id
			      ) oa
	WHERE	misd.create_dt >= @dt_start
			AND	misd.create_dt <= @dt_finish
