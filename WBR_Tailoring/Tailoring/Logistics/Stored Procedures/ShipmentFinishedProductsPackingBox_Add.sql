CREATE PROCEDURE [Logistics].[ShipmentFinishedProductsPackingBox_Add]
	@sfp_id INT,
	@packing_box_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.order_wb IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не присвоен заказ ВБ.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pb.packing_box_id IS NULL THEN 'Коробка не валидная, используйте другой шк'
	      	                   WHEN pb.packing_box_id IS NOT NULL AND psfppb.packing_box_id IS NULL THEN 'Коробка не запланирована в отгрузку'
	      	                   WHEN psfppb.packing_box_id IS NOT NULL AND psfppb.sfp_id != @sfp_id THEN 'Коробка запланирована в другую отгрузку, № '+ CAST(psfppb.sfp_id AS VARCHAR(10))
	      	                   WHEN sfppb.packing_box_id IS NOT NULL AND  sfppb.sfp_id = @sfp_id THEN 'Коробка уже запикана в эту отгрузку'
	      	                   WHEN sfppb.packing_box_id IS NOT NULL AND  sfppb.sfp_id != @sfp_id THEN 'Коробка уже запикана в в другую отгрузку, № '+ CAST(sfppb.sfp_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@packing_box_id))v(packing_box_id)   
			LEFT JOIN	Logistics.PackingBox pb
				ON	pb.packing_box_id = v.packing_box_id
			LEFT JOIN Logistics.PlanShipmentFinishedProductsPackingBox psfppb
				ON psfppb.packing_box_id = pb.packing_box_id 
			LEFT JOIN Logistics.ShipmentFinishedProductsPackingBox sfppb
				ON sfppb.packing_box_id = pb.packing_box_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END  
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		UPDATE	Logistics.PackingBox
		SET 	close_dt = @dt,
				close_employee_id = @employee_id
		WHERE	close_dt IS NULL
		AND packing_box_id = @packing_box_id
			
		INSERT INTO Logistics.ShipmentFinishedProductsPackingBox
		(
			sfp_id,
			packing_box_id,
			dt,
			employee_id
		)
		VALUES
			(
				@sfp_id,
				@packing_box_id,
				@dt,
				@employee_id
			)
		
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