CREATE PROCEDURE [Logistics].[PackingBox_Add]
@count SMALLINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @place_id INT
	DECLARE @proc_id INT
	DECLARE @tab_out TABLE (packing_box_id INT)
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	IF @count > 50
	BEGIN
	    RAISERROR('Нельзя печатать больше 50 наклеек единовременно', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN es.employee_id IS NULL THEN 'Сотрудника с кодом ' + CAST(v.employee_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN es.employee_id IS NOT NULL AND es.office_id IS NULL THEN 'У сотрудника ' + es.employee_name +
	      	                        ' не заполнен офис, в котором он работает'
	      	                   ELSE NULL
	      	              END,
			@place_id = os.buffer_zone_place_id
	FROM	(VALUES(@employee_id))v(employee_id)   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = v.employee_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.office_id = es.office_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Logistics.PackingBox
			(
				create_dt,
				create_employee_id
			)OUTPUT	INSERTED.packing_box_id
			 INTO	@tab_out (
			 		packing_box_id
			 	)
		SELECT	@dt,
				@employee_id
		FROM	dbo.Number n
		WHERE	n.id > 0
				AND	n.id <= @count
		
		
		INSERT INTO Warehouse.PackingBoxOnPlace
			(
				packing_box_id,
				place_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.packing_box_id,
			 		INSERTED.place_id,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		@proc_id
			 INTO	History.PackingBoxOnPlace (
			 		packing_box_id,
			 		place_id,
			 		dt,
			 		employee_id,
			 		proc_id
			 	)
		SELECT	tot.packing_box_id,
				@place_id,
				@dt,
				@employee_id
		FROM	@tab_out tot
		
		SELECT	tot.packing_box_id
		FROM	@tab_out tot
		
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