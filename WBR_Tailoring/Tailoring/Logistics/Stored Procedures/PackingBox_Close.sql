CREATE PROCEDURE [Logistics].[PackingBox_Close]
	@packing_box_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @place_id INT
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   WHEN pb.close_dt IS NOT NULL THEN 'Коробка ' + CAST(pb.packing_box_id AS VARCHAR(10)) + ' уже закрыта.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@packing_box_id))v(packing_box_id)   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = v.packing_box_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
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
		
		UPDATE	Logistics.PackingBox
		SET 	close_dt              = @dt,
				close_employee_id     = @employee_id
		WHERE	close_dt IS NULL
				AND	packing_box_id = @packing_box_id
		
		;
		MERGE Warehouse.PackingBoxOnPlace t
		USING (
		      	SELECT	@packing_box_id     packing_box_id,
		      			@place_id           place_id,
		      			@dt                 dt,
		      			@employee_id        employee_id
		      ) s
				ON s.packing_box_id = t.packing_box_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		packing_box_id,
		     		place_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.packing_box_id,
		     		s.place_id,
		     		s.dt,
		     		s.employee_id
		     	) 
		     OUTPUT	INSERTED.packing_box_id,
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 	