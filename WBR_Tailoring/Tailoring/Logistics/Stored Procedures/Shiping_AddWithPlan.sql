CREATE PROCEDURE [Logistics].[Shiping_AddWithPlan]
	@ps_id INT,
	@employee_id INT,
	@vehicle_id INT,
	@driver_id INT,
	@seal1 VARCHAR(20) = NULL,
	@seal2 VARCHAR(20) = NULL,
	@towed_vehicle_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @shipping_output TABLE (shipping_id INT)
	DECLARE @ttn_output TABLE (ttn_id INT)
	DECLARE @src_office_id INT
	DECLARE @dst_office_id INT
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.Vehicle v
	   	WHERE	v.vehicle_id = @vehicle_id
	   )
	BEGIN
	    RAISERROR('Автомобиля с кодом %d не существует', 16, 1, @vehicle_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Logistics.Driver d
	   	WHERE	d.driver_id = @driver_id
	   )
	BEGIN
	    RAISERROR('Водителя с кодом %d не существует', 16, 1, @driver_id)
	    RETURN
	END
	
	IF @towed_vehicle_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Logistics.Vehicle v
	       	WHERE	v.vehicle_id = @towed_vehicle_id
	       )
	BEGIN
	    RAISERROR('Прицепа с кодом %d не существует', 16, 1, @towed_vehicle_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ps.ps_id IS NULL THEN 'Плановой отгрузки с номером ' + CAST(v.ps_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ps.ttn_id IS NOT NULL THEN 'На эту плановую отгрузку уже создана фактическая отгрузка с номером: ' + CAST(t.shipping_id AS VARCHAR(10)) 
	      	                        + ' ,номер ттн: ' 
	      	                        + CAST(t.ttn_id AS VARCHAR(10))
	      	                   WHEN ps.close_dt IS NOT NULL THEN 'Плановая отгрузка не закрыта, создавать фактическую отгрузку на её основании нельзя'
	      	                   ELSE NULL
	      	              END,
			@src_office_id     = ps.src_office_id,
			@dst_office_id     = ps.dst_office_id
	FROM	(VALUES(@ps_id))v(ps_id)   
			LEFT JOIN	Planing.PlanShipping ps
				ON	ps.ps_id = v.ps_id   
			LEFT JOIN	Logistics.TTN t
				ON	t.ttn_id = ps.ttn_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Logistics.Shipping
			(
				employee_id,
				dt,
				create_employee_id,
				create_dt,
				close_employee_id,
				close_dt,
				src_office_id,
				complite_employee_id,
				complite_dt,
				is_deleted
			)OUTPUT	INSERTED.shipping_id
			 INTO	@shipping_output (
			 		shipping_id
			 	)
		VALUES
			(
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				NULL,
				NULL,
				@src_office_id,
				NULL,
				NULL,
				0
			)
		
		INSERT INTO Logistics.TTN
			(
				shipping_id,
				src_office_id,
				dst_office_id,
				seal1,
				seal2,
				employee_id,
				dt,
				vehicle_id,
				driver_id,
				towed_vehicle_id,
				complite_employee_id,
				complite_dt,
				is_deleted,
				create_employee_id,
				create_dt
			)OUTPUT	INSERTED.ttn_id
			 INTO	@ttn_output (
			 		ttn_id
			 	)
		SELECT	so.shipping_id,
				@src_office_id,
				@dst_office_id,
				@seal1,
				@seal2,
				@employee_id,
				@dt,
				@vehicle_id,
				@driver_id,
				@towed_vehicle_id,
				NULL,
				NULL,
				0,
				@employee_id,
				@dt
		FROM	@shipping_output so
		
		UPDATE	ps
		SET 	ttn_id = t.ttn_id
		FROM	Planing.PlanShipping ps
				CROSS JOIN	@ttn_output t
		WHERE	ps.ps_id = @ps_id
				AND	ps.ttn_id IS NULL
				AND t.ttn_id IS NOT NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Что-то пошло не так, возможно кто-то уже создал отгрузку.', 16, 1)
		    RETURN
		END
		
		COMMIT TRANSACTION
		
		SELECT	s.shipping_id,
				t.ttn_id
		FROM	@ttn_output t   
				CROSS JOIN	@shipping_output s
				
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