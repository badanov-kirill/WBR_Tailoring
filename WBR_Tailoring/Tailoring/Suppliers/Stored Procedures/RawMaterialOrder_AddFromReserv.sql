CREATE PROCEDURE [Suppliers].[RawMaterialOrder_AddFromReserv]
	@supplier_id INT,
	@suppliercontract_id INT = NULL,
	@employee_id INT,
	@data_xml XML,
	@supply_dt DATETIME2(0),
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab TABLE (rmsr_id INT, qty DECIMAL(9, 3), price_cur DECIMAL(9, 2), currency_id INT, spcvc_id INT)
	DECLARE @sketch_plan_tab TABLE(sp_id INT)
	DECLARE @raw_material_order_output TABLE (rmo_id INT)
	DECLARE @rmod_status_ordered TINYINT = 1
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @cvc_state_need_proc TINYINT = 1
	DECLARE @cvc_state_order_sup TINYINT = 2
	DECLARE @cvc_state_covered_wh TINYINT = 3	
	
	DECLARE @status_processed_bayer TINYINT = 8
	DECLARE @cv_status_create TINYINT = 1 --Создан
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.supplier_id IS NULL THEN 'Поставщика с кодом ' + CAST(v.supplier_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
			@suppliercontract_id = ISNULL(@suppliercontract_id, oa.suppliercontract_id)
	FROM	(VALUES(@supplier_id))v(supplier_id)   
			LEFT JOIN	Suppliers.Supplier s
				ON	s.supplier_id = v.supplier_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sc.suppliercontract_id
			      	FROM	Suppliers.SupplierContract sc
			      	WHERE	sc.supplier_id = s.supplier_id
			      	ORDER BY
			      		CASE 
			      		     WHEN sc.is_default = 1 THEN 0
			      		     ELSE 1
			      		END,
			      		sc.suppliercontract_id DESC
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @suppliercontract_id IS NULL
	BEGIN
	    RAISERROR('У поставщика нет договора.', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.SupplierContract sc
	   	WHERE	sc.suppliercontract_id = @suppliercontract_id
	   			AND	sc.supplier_id = @supplier_id
	   )
	BEGIN
	    RAISERROR('Не корректный договор поставщика.', 16, 1)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			rmsr_id,
			qty,
			price_cur,
			currency_id,
			spcvc_id
		)
	SELECT	ml.value('@rmsr', 'int'),
			ml.value('@qty', 'decimal(9,2)'),
			rms.price_cur,
			rms.currency_id,
			rmsr.spcvc_id
	FROM	@data_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Suppliers.RawMaterialStockReserv rmsr   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id
				ON	rmsr.rmsr_id = ml.value('@rmsr',
			'int')
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.rmsr_id IS NULL THEN 'Некорректныый ХМЛ, обратитесь к разработчику.'
	      	                   WHEN dt.price_cur IS NULL OR rmsr.rmsr_id IS NULL THEN 'Резерва с кодом ' + CAST(dt.rmsr_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rms.supplier_id != @supplier_id THEN 'В пакете данных содержатся резервы разных поставщиков'
	      	                        -- WHEN dt.qty > rms.qty THEN 'Заказ превышает остаток поставщика'
	      	                   WHEN oa.rmo_id IS NOT NULL THEN 'По резерву с кодом ' + CAST(dt.rmsr_id AS VARCHAR(10)) + ' уже оформлен заказ номер ' + CAST(oa.rmo_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Suppliers.RawMaterialStockReserv rmsr   
			INNER JOIN	Suppliers.RawMaterialStock rms
				ON	rms.rms_id = rmsr.rms_id
				ON	rmsr.rmsr_id = dt.rmsr_id   
			OUTER APPLY (
			      	SELECT	TOP(1) rmodfr.rmo_id
			      	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
			      			INNER JOIN	Suppliers.RawMaterialOrder rmo
			      				ON	rmo.rmo_id = rmodfr.rmo_id
			      	WHERE	rmodfr.rmsr_id = dt.rmsr_id
			      			AND	rmo.is_deleted = 0
			      			AND	rmodfr.rmods_id != 2
			      ) oa
	WHERE	dt.rmsr_id IS NULL
			OR	dt.price_cur IS NULL
			OR	rmsr.rmsr_id IS NULL
			OR	rms.supplier_id != @supplier_id
			  	--OR	dt.qty > rms.qty
			OR	oa.rmo_id IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @sketch_plan_tab
		(
			sp_id
		)
	SELECT	DISTINCT spcv.sp_id
	FROM	@data_tab dt   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = dt.spcvc_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Suppliers.RawMaterialOrder
			(
				create_dt,
				create_employee_id,
				supplier_id,
				suppliercontract_id,
				supply_dt,
				is_deleted,
				comment,
				employee_id,
				dt
			)OUTPUT	INSERTED.rmo_id
			 INTO	@raw_material_order_output (
			 		rmo_id
			 	)
		VALUES
			(
				@dt,
				@employee_id,
				@supplier_id,
				@suppliercontract_id,
				@supply_dt,
				0,
				@comment,
				@employee_id,
				@dt
			)
		
		INSERT INTO Suppliers.RawMaterialOrderDetailFromReserv
			(
				rmo_id,
				rmsr_id,
				qty,
				price_cur,
				currency_id,
				rmods_id,
				employee_id,
				dt
			)
		SELECT	rmoo.rmo_id,
				dt.rmsr_id,
				dt.qty,
				dt.price_cur,
				dt.currency_id,
				@rmod_status_ordered,
				@employee_id,
				@dt
		FROM	@data_tab dt   
				CROSS JOIN	@raw_material_order_output rmoo 
		
		UPDATE	cvc
		SET 	cs_id = @cvc_state_order_sup,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.spcvc_id,
						INSERTED.spcv_id,
						INSERTED.completing_id,
						INSERTED.completing_number,
						INSERTED.rmt_id,
						INSERTED.color_id,
						INSERTED.frame_width,
						INSERTED.okei_id,
						INSERTED.consumption,
						INSERTED.comment,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.cs_id,
						@proc_id
				INTO	History.SketchPlanColorVariantCompleting (
						spcvc_id,
						spcv_id,
						completing_id,
						completing_number,
						rmt_id,
						color_id,
						frame_width,
						okei_id,
						consumption,
						comment,
						dt,
						employee_id,
						cs_id,
						proc_id
					)
		FROM	Planing.SketchPlanColorVariantCompleting cvc
				INNER JOIN	@data_tab dt
					ON	dt.spcvc_id = cvc.spcvc_id
		WHERE cvc.cs_id = @cvc_state_need_proc
		
		UPDATE	spcv
		SET 	cvs_id = @cv_status_ready,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.spcv_id,
						INSERTED.sp_id,
						INSERTED.spcv_name,
						INSERTED.cvs_id,
						INSERTED.qty,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.is_deleted,
						INSERTED.comment,
						INSERTED.pan_id,
						INSERTED.corrected_qty,
						INSERTED.begin_plan_delivery_dt,
						INSERTED.end_plan_delivery_dt,
						INSERTED.sew_office_id,
						INSERTED.sew_deadline_dt,
						INSERTED.cost_plan_year,
						INSERTED.cost_plan_month,
						@proc_id
				INTO	History.SketchPlanColorVariant (
						spcv_id,
						sp_id,
						spcv_name,
						cvs_id,
						qty,
						employee_id,
						dt,
						is_deleted,
						comment,
						pan_id,
						corrected_qty,
						begin_plan_delivery_dt,
						end_plan_delivery_dt,
						sew_office_id,
						sew_deadline_dt,
						cost_plan_year,
						cost_plan_month,
						proc_id
					)
		FROM	Planing.SketchPlanColorVariant spcv
				INNER JOIN	@sketch_plan_tab spt
					ON	spt.sp_id = spcv.sp_id
		WHERE	cvs_id = @cv_status_create
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Planing.SketchPlanColorVariantCompleting spcvc
				   		WHERE	spcvc.spcv_id = spcv.spcv_id
				   				AND	spcvc.cs_id != @cvc_state_covered_wh
				   	)
		
		UPDATE	sp
		SET 	ps_id = @status_processed_bayer,
				employee_id = @employee_id,
				dt = @dt
				OUTPUT	INSERTED.sp_id,
						INSERTED.sketch_id,
						INSERTED.ps_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.comment
				INTO	History.SketchPlan (
						sp_id,
						sketch_id,
						ps_id,
						employee_id,
						dt,
						comment
					)
		FROM	Planing.SketchPlan sp
				INNER JOIN	@sketch_plan_tab spt
					ON	spt.sp_id = sp.sp_id
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariant spcv   
		     				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
		     					ON	spcvc.spcv_id = spcv.spcv_id
		     		WHERE	spcv.sp_id = sp.sp_id
		     				AND	spcvc.cs_id NOT IN (@cvc_state_order_sup, @cvc_state_covered_wh)
		     				AND	spcv.is_deleted = 0
		     	) 
		
		COMMIT TRANSACTION
		
		SELECT	rmoo.rmo_id
		FROM	@raw_material_order_output rmoo
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 