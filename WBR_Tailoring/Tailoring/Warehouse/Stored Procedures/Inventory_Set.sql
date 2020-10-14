CREATE PROCEDURE [Warehouse].[Inventory_Set]
	@inventory_id INT = NULL,
	@plan_start_dt DATE,
	@plan_finish_dt DATE,
	@employee_id INT,
	@it_id TINYINT,
	@comment VARCHAR(300) = NULL,
	@rmt_id INT = NULL,
	@employee_xml XML = NULL,
	@place_xml XML = NULL,
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @employee_tab TABLE(employee_id INT)
	DECLARE @place_tab TABLE (place_id INT)
	DECLARE @inventory_out TABLE (inventory_id INT)
	
	IF @inventory_id IS NULL
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN i.inventory_id IS NULL THEN 'Инвентаризации с кодом ' + CAST(v.inventory_id AS VARCHAR(10)) + ' не существует'
	          	                   WHEN i.close_dt IS NOT NULL THEN 'Инвентаризация № ' + CAST(v.inventory_id AS VARCHAR(10)) +
	          	                        ' уже закрыта, редакторовать нельзя.'
	          	                   ELSE NULL
	          	              END
	    FROM	(VALUES(@inventory_id))v(inventory_id)   
	    		LEFT JOIN	Warehouse.Inventory i
	    			ON	i.inventory_id = v.inventory_id
	    
	    IF @error_text IS NOT NULL
	    BEGIN
	        RAISERROR('%s', 16, 1, @error_text)
	        RETURN
	    END
	END
	
	IF @rmt_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Material.RawMaterialType rmt
	       	WHERE	rmt.rmt_id = @rmt_id
	       )
	BEGIN
	    RAISERROR('Материала с кодом %d не существует', 16, 1, @rmt_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Warehouse.InventoryType it
	   	WHERE	it.it_id = @it_id
	   )
	BEGIN
	    RAISERROR('Типа инвентаризации с кодом %d не существует', 16, 1, @it_id)
	    RETURN
	END
	
	INSERT INTO @employee_tab
		(
			employee_id
		)
	SELECT	ml.value('@empl[1]', 'int')
	FROM	@employee_xml.nodes('root/det')x(ml)
	
	INSERT INTO @place_tab
		(
			place_id
		)
	SELECT	ml.value('@place[1]', 'int')
	FROM	@place_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.place_id IS NULL THEN 'Некорректный XML МХ'
	      	                   WHEN dt.place_id IS NOT NULL AND sp.place_id IS NULL THEN 'МХ с кодом ' + CAST(dt.place_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@place_tab dt   
			LEFT JOIN	Warehouse.StoragePlace sp
				ON	sp.place_id = dt.place_id
	WHERE	dt.place_id IS NULL
			OR	sp.place_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.employee_id IS NULL THEN 'Некорректный XML сотрудников'
	      	                   WHEN dt.employee_id IS NOT NULL AND es.employee_id IS NULL THEN 'Сотрудника с кодом ' + CAST(dt.employee_id AS VARCHAR(10)) +
	      	                        'не существует'
	      	                   ELSE NULL
	      	              END
	FROM	@employee_tab dt   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = dt.employee_id
	WHERE	dt.employee_id IS NULL
			OR	es.employee_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		IF @inventory_id IS NULL
		BEGIN
		    INSERT INTO Warehouse.Inventory
		    	(
		    		plan_start_dt,
		    		plan_finish_dt,
		    		create_dt,
		    		create_employee_id,
		    		it_id,
		    		comment,
		    		rmt_id,
		    		is_deleted,
		    		dt,
		    		employee_id
		    	)OUTPUT	INSERTED.inventory_id
		    	 INTO	@inventory_out (
		    	 		inventory_id
		    	 	)
		    VALUES
		    	(
		    		@plan_start_dt,
		    		@plan_finish_dt,
		    		@dt,
		    		@employee_id,
		    		@it_id,
		    		@comment,
		    		@rmt_id,
		    		0,
		    		@dt,
		    		@employee_id
		    	)
		END
		ELSE
		BEGIN
		    UPDATE	Warehouse.Inventory
		    SET 	plan_start_dt = @plan_start_dt,
		    		plan_finish_dt = @plan_finish_dt,
		    		it_id = @it_id,
		    		comment = @comment,
		    		rmt_id = @rmt_id,
		    		is_deleted = @is_deleted,
		    		dt = @dt,
		    		employee_id = @employee_id
		    		OUTPUT	INSERTED.inventory_id
		    		INTO	@inventory_out (
		    				inventory_id
		    			)
		    WHERE	inventory_id = @inventory_id
		    		AND	close_dt IS NULL
		    
		    IF NOT EXISTS (
		       	SELECT	1
		       	FROM	@inventory_out i
		       )
		    BEGIN
		        ROLLBACK TRANSACTION
		        RAISERROR('Пока форма была открыта, документ закрыли, редактировать нельзя', 16, 1)
		        RETURN
		    END
		END;
		
		WITH cte_target AS (
			SELECT	ie.inventory_id,
					ie.employee_id
			FROM	Warehouse.InventoryEmployee ie   
					INNER JOIN	@inventory_out i
						ON	i.inventory_id = ie.inventory_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	i.inventory_id,
		      			et.employee_id
		      	FROM	@employee_tab et   
		      			CROSS JOIN	@inventory_out i
		      ) s
				ON t.employee_id = s.employee_id
				AND t.inventory_id = s.inventory_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		inventory_id,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.inventory_id,
		     		s.employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_target AS (
			SELECT	isp.inventory_id,
					isp.place_id
			FROM	Warehouse.InventoryStoragePlace isp   
					INNER JOIN	@inventory_out i
						ON	i.inventory_id = isp.inventory_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	i.inventory_id,
		      			pt.place_id
		      	FROM	@place_tab pt   
		      			CROSS JOIN	@inventory_out i
		      ) s
				ON t.place_id = s.place_id
				AND t.inventory_id = s.inventory_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		inventory_id,
		     		place_id
		     	)
		     VALUES
		     	(
		     		s.inventory_id,
		     		s.place_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		COMMIT TRANSACTION
		
		SELECT	iou.inventory_id
		FROM	@inventory_out iou
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