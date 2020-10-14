CREATE PROCEDURE [Warehouse].[PackingBoxOnPlace_Set]
	@packing_box_id INT,
	@place_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   WHEN pb.close_dt IS NULL THEN 'Коробка ' + CAST(pb.packing_box_id AS VARCHAR(10)) + ' не закрыта.'
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
	      	                   WHEN sp.place_id IS NULL THEN 'Места хранения с кодом ' + CAST(v.place_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sp.is_deleted = 1 THEN 'Место хранения ' + sp.place_name + ' удалено.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@place_id))v(place_id)   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = v.place_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		;
		MERGE Warehouse.PackingBoxOnPlace t
		USING (
		      	SELECT	@packing_box_id       packing_box_id,
		      			@place_id        place_id,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.packing_box_id = t.packing_box_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	packing_box_id       = s.packing_box_id,
		     		place_id        = s.place_id,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 