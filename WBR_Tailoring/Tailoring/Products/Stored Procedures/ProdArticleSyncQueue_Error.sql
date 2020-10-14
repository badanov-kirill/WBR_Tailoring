CREATE PROCEDURE [Products].[ProdArticleSyncQueue_Error]
	@pa_id INT,
	@rv_bigint VARCHAR(20),
	@pass_id TINYINT,
	@spec_uid VARCHAR(36) = NULL,
	@comment VARCHAR(200) = NULL,
	@data_send VARCHAR(MAX) = NULL,
	@data_answer VARCHAR(MAX) = NULL,
	@data_request VARCHAR(MAX) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	
		FROM	Products.ProdArticleSyncQueue
		WHERE	pa_id = @pa_id
				AND	rv = @rv
		
		INSERT INTO Products.ProdArticleSyncError
		  (
		    pass_id,
		    pa_id,
		    spec_uid,
		    comment,
		    dt,
		    data_send,
		    data_error
		  )
		VALUES
		  (
		    @pass_id,
		    @pa_id,
		    @spec_uid,
		    @comment,
		    @dt,
		    @data_send,
		    ISNULL(@data_answer, @data_request)
		  )
		
		IF @data_send IS NOT NULL
		BEGIN
		    INSERT INTO History.ProdArticleSyncDataSend
		      (
		        dt,
		        pa_id,
		        data_send,
		        data_answer,
		        spec_uid
		      )
		    VALUES
		      (
		        @dt,
		        @pa_id,
		        @data_send,
		        @data_answer,
		        @spec_uid
		      )
		END
		
		IF @data_request IS NOT NULL
		BEGIN
		    INSERT INTO History.ProdArticleSyncDataRequest
		      (
		        dt,
		        pa_id,
		        spec_uid,
		        data_request
		      )
		    VALUES
		      (
		        @dt,
		        @pa_id,
		        @spec_uid,
		        @data_request
		      )
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 