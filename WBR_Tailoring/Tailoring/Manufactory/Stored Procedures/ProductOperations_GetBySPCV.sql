CREATE PROCEDURE [Manufactory].[ProductOperations_GetBySPCV]
	@spcv_id INT,
	@operation_id SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	po.product_unic_code,
			CAST(po.dt AS DATETIME) dt,
			o.operation_name,
			es.employee_name,
			os.office_name,
			ts.ts_name
	FROM	Planing.SketchPlanColorVariantTS spcvt
			INNER JOIN Products.TechSize ts
				ON ts.ts_id = spcvt.ts_id   
			INNER JOIN	Manufactory.Cutting c
				ON	c.spcvts_id = spcvt.spcvts_id   
			INNER JOIN	Manufactory.ProductUnicCode puc
				ON	puc.cutting_id = c.cutting_id   
			INNER JOIN	Manufactory.ProductOperations po
				ON	po.product_unic_code = puc.product_unic_code   
			INNER JOIN	Manufactory.Operation o
				ON	o.operation_id = po.operation_id   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	po.employee_id = es.employee_id   
			INNER JOIN	Settings.OfficeSetting os
				ON	po.office_id = os.office_id
	WHERE	spcvt.spcv_id = @spcv_id
			AND	(@operation_id IS NULL OR po.operation_id = @operation_id)
	ORDER BY po.po_id