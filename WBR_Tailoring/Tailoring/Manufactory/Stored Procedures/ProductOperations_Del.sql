CREATE PROCEDURE [Manufactory].[ProductOperations_Del]
	@po_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @DeleteData TABLE (
	        	po_id INT NOT NULL,
	        	product_unic_code INT NOT NULL,
	        	operation_id SMALLINT NOT NULL,
	        	office_id INT NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL
	        )
	
	DECLARE @spcv_id INT
	DECLARE @spcvts_id INT
	DECLARE @operation_id SMALLINT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @packaging_operation SMALLINT = 8
	DECLARE @cancellation_operation SMALLINT = 3
	DECLARE @cut_wtite_off_operation INT = 12	
	
	SELECT	@error_text = CASE 
	      	                   WHEN puc.product_unic_code IS NULL THEN 'Операции с кодом ' + CAST(v.po_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
			@spcv_id          = spcvt.spcv_id,
			@spcvts_id          = spcvt.spcvts_id,
			@operation_id     = po.operation_id
	FROM	(VALUES(@po_id))v(po_id)   
			LEFT JOIN	Manufactory.ProductOperations po
				ON	po.po_id = v.po_id   
			LEFT JOIN	Manufactory.ProductUnicCode puc ON puc.product_unic_code = po.product_unic_code   
			LEFT JOIN	Manufactory.Cutting c   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = c.spcvts_id
				ON	c.cutting_id = puc.cutting_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	
		FROM	Manufactory.ProductOperations
		    	OUTPUT	DELETED.po_id,
		    			DELETED.product_unic_code,
		    			DELETED.operation_id,
		    			DELETED.office_id,
		    			DELETED.employee_id,
		    			DELETED.dt
		    	INTO	@DeleteData (
		    			po_id,
		    			product_unic_code,
		    			operation_id,
		    			office_id,
		    			employee_id,
		    			dt
		    		)
		WHERE	po_id = @po_id
		
		;
		WITH target_cte
		AS
		(
			SELECT	puc.product_unic_code,
					puc.pants_id,
					puc.operation_id,
					puc.dt,
					puc.pt_id,
					puc.cutting_id
			FROM	Manufactory.ProductUnicCode puc   
					INNER JOIN	@DeleteData dd
						ON	dd.product_unic_code = puc.product_unic_code
		)
		MERGE target_cte t
		USING (
		      	SELECT	TOP 1 po.operation_id,
		      			po.product_unic_code,
		      			po.dt,
		      			CASE 
		      			     WHEN po.po_id < dd.po_id THEN 1
		      			     ELSE 0
		      			END      is_del_last_op
		      	FROM	Manufactory.ProductOperations po   
		      			INNER JOIN	@DeleteData dd
		      				ON	dd.product_unic_code = po.product_unic_code
		      	ORDER BY
		      		po.po_id     DESC
		      ) s
				ON t.product_unic_code = t.product_unic_code
		WHEN MATCHED AND s.is_del_last_op = 1 THEN 
		     UPDATE	
		     SET 	operation_id     = s.operation_id,
		     		dt               = s.dt
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;		
		
		INSERT INTO Manufactory.DeleteProductOperations
			(
				po_id,
				product_unic_code,
				operation_id,
				office_id,
				employee_id,
				dt,
				delete_employee_id
			)
		SELECT	dd.po_id,
				dd.product_unic_code,
				dd.operation_id,
				dd.office_id,
				dd.employee_id,
				dd.dt,
				@employee_id     delete_employee_id
		FROM	@DeleteData      dd 
		
		IF @spcv_id IS NOT NULL
		   AND @operation_id IN (@packaging_operation, @cancellation_operation, @cut_wtite_off_operation)
		BEGIN
		    UPDATE	Planing.SketchPlanColorVariantCounter
		    SET 	packaging     = CASE 
		        	                 WHEN @operation_id = @packaging_operation THEN packaging - 1
		        	                 ELSE packaging
		        	            END,
		    		write_off     = CASE 
		    		                 WHEN @operation_id = @cancellation_operation THEN write_off - 1
		    		                 ELSE write_off
		    		            END,
		    		cut_write_off =  CASE 
		    		                 WHEN @operation_id = @cut_wtite_off_operation THEN cut_write_off - 1
		    		                 ELSE cut_write_off
		    		            END,
		    		finished = CASE 
		    		                 WHEN @operation_id IN (@packaging_operation, @cancellation_operation, @cut_wtite_off_operation) THEN finished - 1
		    		                 ELSE finished
		    		            END,
		    		dt_close = CASE 
		    		                WHEN cutting_qty <= CASE 
		    		                                         WHEN @operation_id IN (@packaging_operation, @cancellation_operation, @cut_wtite_off_operation) THEN 
		    		                                              finished - 1
		    		                                         ELSE finished
		    		                                    END THEN ISNULL(dt_close, @dt)
		    		                ELSE NULL
		    		           END 
		    WHERE	spcv_id       = @spcv_id
		    
		    UPDATE	Planing.SketchPlanColorVariantTSCounter
		    SET 	packaging     = CASE 
		        	                 WHEN @operation_id = @packaging_operation THEN packaging - 1
		        	                 ELSE packaging
		        	            END,
		    		write_off     = CASE 
		    		                 WHEN @operation_id = @cancellation_operation THEN write_off - 1
		    		                 ELSE write_off
		    		            END,
		    		cut_write_off =  CASE 
		    		                 WHEN @operation_id = @cut_wtite_off_operation THEN cut_write_off - 1
		    		                 ELSE cut_write_off
		    		            END,
		    		finished = CASE 
		    		                 WHEN @operation_id IN (@packaging_operation, @cancellation_operation, @cut_wtite_off_operation) THEN finished - 1
		    		                 ELSE finished
		    		            END
		    WHERE	spcvts_id       = @spcvts_id
		END
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