CREATE PROCEDURE [Synchro].[ERP_NM_Add]
	@nm_id INT,
	@imt_id INT,
	@sa VARCHAR(36),
	@vc_log_id VARCHAR(20)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @log_id BIGINT = CAST(@vc_log_id AS BIGINT)
	
	DECLARE @is_tailoring BIT = 0
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ERP_IMT_Sketch eis
	   	WHERE	eis.imt_id = @imt_id
	   )
	   OR EXISTS (
	      	SELECT	1
	      	FROM	Products.ERP_IMT_ForMapping eifm
	      	WHERE	eifm.imt_id = @imt_id
	      )
	BEGIN
	    SET @is_tailoring = 1
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		MERGE Synchro.ERP_NM t
		USING (
		      	SELECT	@nm_id       nm_id,
		      			@imt_id      imt_id,
		      			@sa          sa
		      ) s
				ON t.nm_id = s.nm_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.imt_id = s.imt_id,
		     		t.sa = s.sa
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		nm_id,
		     		imt_id,
		     		sa
		     	)
		     VALUES
		     	(
		     		s.nm_id,
		     		s.imt_id,
		     		s.sa
		     	);
		
		IF @is_tailoring = 1
		BEGIN
		    INSERT INTO Products.ERP_NM_Sketch
		    	(
		    		nm_id,
		    		imt_id,
		    		sa
		    	)
		    SELECT	@nm_id,
		    		@imt_id,
		    		@sa
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	Products.ERP_NM_Sketch ens
		         		WHERE	ens.nm_id = @nm_id
		         	)
		END
		
		UPDATE	Synchro.RV
		SET 	object_rv = CASE 
		    	                 WHEN object_rv > @log_id THEN object_rv
		    	                 ELSE @log_id
		    	            END,
				dt = @dt
		WHERE	ob_name = 'ERP_NM'
		
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
	