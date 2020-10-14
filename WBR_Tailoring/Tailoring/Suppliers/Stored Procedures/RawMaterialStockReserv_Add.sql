CREATE PROCEDURE [Suppliers].[RawMaterialStockReserv_Add]
	@rms_id INT,
	@spcvc_id INT,
	@qty DECIMAL(15, 3),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rmod_status_deleted TINYINT = 2 -- удален
	
	SELECT	@error_text = CASE 
	      	                   WHEN rms.rms_id IS NULL THEN 'Остатка материала поставщика с кодом ' + CAST(v.rms_id AS VARCHAR(10)) + ' не существует.'
	      	                        --WHEN rms.end_dt_offer > @dt THEN 'Остатки не актуальны, резервировать нельзя.'
	      	                        -- WHEN oa.sum_qty + @qty > rms.qty THEN 'Из остатка ' + CAST(rms.qty AS VARCHAR(16)) + ' уже зарезервировано ' + CAST(oa.sum_qty AS VARCHAR(16))
	      	                        --      + ', нельзя зарезервировать ещё ' + CAST(@qty AS VARCHAR(16))
	      	                   --WHEN oa.rmo_id IS NOT NULL THEN 'По этой позиции уже есть заказ №' + CAST(oa.rmo_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rms_id))v(rms_id)   
			LEFT JOIN	Suppliers.RawMaterialStock rms
				ON	v.rms_id = rms.rms_id   
			OUTER APPLY (
			      	SELECT	SUM(rmsr.qty) sum_qty,
			      			MAX(rmodfr.rmo_id) rmo_id
			      	FROM	Suppliers.RawMaterialStockReserv rmsr   
			      			LEFT JOIN	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
			      				ON	rmodfr.rmsr_id = rmsr.rmsr_id
			      				AND	rmsr.spcvc_id = @spcvc_id
			      				AND	rmodfr.rmods_id != 2
			      	WHERE	rmsr.rms_id = v.rms_id
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.SketchPlanColorVariantCompleting spcvc
	   	WHERE	spcvc.spcvc_id = @spcvc_id
	   )
	BEGIN
	    RAISERROR('Строчки плана с кодом %d не существует.', 16, 1, @spcvc_id)
	    RETURN
	END
	
	BEGIN TRY
	BEGIN TRANSACTION
		DELETE	rmodfr
		FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr   
				INNER JOIN	Suppliers.RawMaterialStockReserv r
					ON	r.rmsr_id = rmodfr.rmsr_id
		WHERE	r.spcvc_id = @spcvc_id
				AND	rmodfr.rmods_id = @rmod_status_deleted
				AND NOT EXISTS (
				               	SELECT	1
				               	FROM	Material.RawMaterialIncomeOrderReservRelationDetail rmiorrd
				               	WHERE	rmodfr.rmodr_id = rmiorrd.rmodr_id
				               )
		
		DELETE	r
		FROM	Suppliers.RawMaterialStockReserv r
		WHERE	r.spcvc_id = @spcvc_id
		AND NOT EXISTS(
		              	SELECT	1
		              	FROM	Suppliers.RawMaterialOrderDetailFromReserv rmodfr
		              	WHERE	rmodfr.rmsr_id = r.rmsr_id
		              )
		
		;
		MERGE Suppliers.RawMaterialStockReserv t
		USING (
		      	SELECT	@rms_id       rms_id,
		      			@spcvc_id     spcvc_id,
		      			@qty          qty
		      ) s
				ON t.rms_id = s.rms_id
				AND t.spcvc_id = s.spcvc_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.qty = s.qty,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		rms_id,
		     		spcvc_id,
		     		qty,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.rms_id,
		     		s.spcvc_id,
		     		s.qty,
		     		@dt,
		     		@employee_id
		     	);
		   
	COMMIT TRANSACTION
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