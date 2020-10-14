CREATE PROCEDURE [Planing].[SketchPlanSupplierPrice_Add]
	@sp_id INT,
	@supplier_id INT,
	@price_ru DECIMAL(9, 2),
	@employee_id INT,
	@comment VARCHAR(200) = NULL,
	@order_num VARCHAR(10) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @status_sided_tailoring TINYINT = 9
	DECLARE @status_sided_order_is_signed TINYINT = 11
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Строчки плана с кодом ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sp.ps_id NOT IN (@status_sided_tailoring, @status_sided_order_is_signed) THEN 'Строчка плана находится в статусе ' + ps.ps_name +
	      	                        ', добавлять цены поставщиков нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp   
			INNER JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id
				ON	sp.sp_id = v.sp_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.Supplier s
	   	WHERE	s.supplier_id = @supplier_id
	   )
	BEGIN
	    RAISERROR('Поставщика с кодом %d не существует.', 16, 1, @supplier_id)
	    RETURN
	END
	
	IF ISNULL(@price_ru, 0) <= 0
	BEGIN
	    RAISERROR('Не корректная цена', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Planing.SketchPlanSupplierPrice t
		USING (
		      	SELECT	@sp_id           sp_id,
		      			@supplier_id     supplier_id,
		      			@price_ru        price_ru,
		      			@employee_id     employee_id,
		      			@dt              dt,
		      			@comment         comment,
		      			@order_num		 order_num
		      ) s
				ON t.sp_id = s.sp_id
				AND t.supplier_id = s.supplier_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.price_ru = s.price_ru,
		     		t.dt = s.dt,
		     		t.employee_id = s.employee_id,
		     		t.comment = s.comment,
		     		order_num = s.order_num
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		sp_id,
		     		supplier_id,
		     		price_ru,
		     		dt,
		     		employee_id,
		     		comment,
		     		order_num
		     	)
		     VALUES
		     	(
		     		s.sp_id,
		     		s.supplier_id,
		     		s.price_ru,
		     		s.dt,
		     		s.employee_id,
		     		s.comment,
		     		s.order_num
		     	)
		     OUTPUT	INSERTED.spsp_id,
		     		INSERTED.sp_id,
		     		INSERTED.supplier_id,
		     		INSERTED.price_ru,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		INSERTED.comment,
		     		INSERTED.order_num
		     INTO	History.SketchPlanSupplierPrice (
		     		spsp_id,
		     		sp_id,
		     		supplier_id,
		     		price_ru,
		     		dt,
		     		employee_id,
		     		comment,
		     		order_num
		     	);
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
	