CREATE PROCEDURE [Logistics].[ShipmentFinishedProducts_CloseForPlaning]
	@sfp_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @supplier_id INT
	DECLARE @ozon_supplier_id INT = -167
	DECLARE @detmir_supplier_id INT = -280
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sfp_id IS NULL THEN 'Отгрузки с номером ' + CAST(v.sfp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.complite_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже отправлена'
	      	                   WHEN s.close_planing_dt IS NOT NULL THEN 'Отгрузка № ' + CAST(s.sfp_id AS VARCHAR(10)) + ' уже закрыта для планирования'
	      	                   ELSE NULL
	      	              END,
	      	@supplier_id = s.supplier_id
	FROM	(VALUES(@sfp_id))v(sfp_id)   
			LEFT JOIN	Logistics.ShipmentFinishedProducts s
				ON	s.sfp_id = v.sfp_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		UPDATE	Logistics.ShipmentFinishedProducts
		SET 	close_planing_dt = @dt,
				dt = @dt,
				employee_id = @employee_id
		WHERE	sfp_id = @sfp_id
		
		DELETE	pbop
		      	OUTPUT	DELETED.packing_box_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.PackingBoxOnPlace (
		      			packing_box_id,
		      			place_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.PackingBoxOnPlace pbop   
				INNER JOIN	Logistics.PlanShipmentFinishedProductsPackingBox psfppb
					ON	psfppb.packing_box_id = pbop.packing_box_id
		WHERE	psfppb.sfp_id = @sfp_id
		
		IF @supplier_id = @ozon_supplier_id
		BEGIN
		    MERGE Synchro.Upload_OzonShip_BuhVas t
		    USING (
		          	SELECT	@sfp_id sfp_id
		          ) s
		    		ON t.sfp_id = s.sfp_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	dt = @dt
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		sfp_id,
		         		dt
		         	)
		         VALUES
		         	(
		         		s.sfp_id,
		         		@dt
		         	);
		END;
		
		IF @supplier_id = @detmir_supplier_id
		BEGIN
		    MERGE Synchro.Upload_DetMirShip_BuhVas t
		    USING (
		          	SELECT	@sfp_id sfp_id
		          ) s
		    		ON t.sfp_id = s.sfp_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	dt = @dt
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		sfp_id,
		         		dt
		         	)
		         VALUES
		         	(
		         		s.sfp_id,
		         		@dt
		         	);
		END;
		
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
GO