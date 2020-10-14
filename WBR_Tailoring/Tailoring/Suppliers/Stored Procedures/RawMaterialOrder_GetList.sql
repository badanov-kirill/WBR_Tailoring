CREATE PROCEDURE [Suppliers].[RawMaterialOrder_GetList]
	@supplier_id INT = NULL,
	@employee_id INT = NULL,
	@dt_start DATETIME2(0),
	@dt_finish DATETIME2(0),
	@art_name VARCHAR(50) = NULL,
	@approve BIT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @art_name IS NOT NULL
	BEGIN
	    SELECT	rmo.rmo_id,
	    		CAST(rmo.create_dt AS DATETIME) create_dt,
	    		rmo.create_employee_id,
	    		rmo.supplier_id,
	    		rmo.suppliercontract_id,
	    		s.supplier_name,
	    		sc.suppliercontract_name,
	    		CAST(rmo.supply_dt AS DATETIME) supply_dt,
	    		rmo.comment,
	    		rmo.employee_id,
	    		CAST(rmo.dt AS DATETIME) dt,
	    		CAST(rmo.approve_dt AS DATETIME) approve_dt
	    FROM	Suppliers.RawMaterialOrder rmo   
	    		INNER JOIN	Suppliers.Supplier s
	    			ON	s.supplier_id = rmo.supplier_id   
	    		INNER JOIN	Suppliers.SupplierContract sc
	    			ON	sc.suppliercontract_id = rmo.suppliercontract_id
	    WHERE	(@employee_id IS NULL OR rmo.create_employee_id = @employee_id)
	    		AND	(@supplier_id IS NULL OR rmo.supplier_id = @supplier_id)
	    		AND	rmo.supply_dt >= @dt_start
	    		AND	rmo.supply_dt <= @dt_finish
	    		AND	rmo.is_deleted = 0
	    		AND (@approve IS NULL OR (@approve = 1 AND rmo.approve_dt IS NOT NULL) OR (@approve = 0 AND rmo.approve_dt IS NULL))  
	    		AND	EXISTS(
	    		   		SELECT	1
	    		   		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
	    		   				INNER JOIN	Suppliers.RawMaterialStockReserv rmsr
	    		   					ON	rmsr.rmsr_id = rmodfr.rmsr_id   
	    		   				INNER JOIN	Suppliers.RawMaterialStock rms
	    		   					ON	rms.rms_id = rmsr.rms_id   
	    		   				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
	    		   					ON	spcvc.spcvc_id = rmsr.spcvc_id   
	    		   				INNER JOIN	Planing.SketchPlanColorVariant spcv
	    		   					ON	spcv.spcv_id = spcvc.spcv_id   
	    		   				INNER JOIN	Planing.SketchPlan sp
	    		   					ON	sp.sp_id = spcv.sp_id   
	    		   				INNER JOIN	Products.Sketch sk
	    		   					ON	sk.sketch_id = sp.sketch_id   
	    		   				INNER JOIN	Products.ArtName an
	    		   					ON	an.art_name_id = sk.art_name_id
	    		   		WHERE	an.art_name LIKE @art_name + '%'
	    		   				AND	rmodfr.rmo_id = rmo.rmo_id
	    		   	)
	END
	ELSE
	BEGIN
	    SELECT	rmo.rmo_id,
	    		CAST(rmo.create_dt AS DATETIME) create_dt,
	    		rmo.create_employee_id,
	    		rmo.supplier_id,
	    		rmo.suppliercontract_id,
	    		s.supplier_name,
	    		sc.suppliercontract_name,
	    		CAST(rmo.supply_dt AS DATETIME) supply_dt,
	    		rmo.comment,
	    		rmo.employee_id,
	    		CAST(rmo.dt AS DATETIME) dt,
	    		CAST(rmo.approve_dt AS DATETIME) approve_dt
	    FROM	Suppliers.RawMaterialOrder rmo   
	    		INNER JOIN	Suppliers.Supplier s
	    			ON	s.supplier_id = rmo.supplier_id   
	    		INNER JOIN	Suppliers.SupplierContract sc
	    			ON	sc.suppliercontract_id = rmo.suppliercontract_id
	    WHERE	(@employee_id IS NULL OR rmo.create_employee_id = @employee_id)
	    		AND	(@supplier_id IS NULL OR rmo.supplier_id = @supplier_id)
	    		AND	rmo.supply_dt >= @dt_start
	    		AND	rmo.supply_dt <= @dt_finish
	    		AND	rmo.is_deleted = 0
	    		AND (@approve IS NULL OR (@approve = 1 AND rmo.approve_dt IS NOT NULL) OR (@approve = 0 AND rmo.approve_dt IS NULL))
	END