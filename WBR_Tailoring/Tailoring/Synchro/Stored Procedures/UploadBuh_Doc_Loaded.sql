CREATE PROCEDURE [Synchro].[UploadBuh_Doc_Loaded]
	@doc_id INT,
	@upload_doc_type_id TINYINT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	
		FROM	Synchro.UploadBuh_Doc
		WHERE	doc_id = @doc_id
				AND	upload_doc_type_id = @upload_doc_type_id
				AND	rv = @rv
		
		IF @@ROWCOUNT > 0
		BEGIN
		    DELETE	
		    FROM	Synchro.UploadBuh_DocInvoice
		    WHERE	doc_id = @doc_id
		    		AND	upload_doc_type_id = @upload_doc_type_id
		    
		    DELETE	
		    FROM	Synchro.UploadBuh_DocDetail
		    WHERE	doc_id = @doc_id
		    		AND	upload_doc_type_id = @upload_doc_type_id	
		    
		    DELETE	
		    FROM	Synchro.UploadBuh_DocInvoiceDetail
		    WHERE	doc_id = @doc_id
		    		AND	upload_doc_type_id = @upload_doc_type_id
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
	
GO


GO

