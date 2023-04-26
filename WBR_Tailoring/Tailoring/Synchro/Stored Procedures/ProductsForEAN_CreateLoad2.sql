CREATE PROCEDURE [Synchro].[ProductsForEAN_CreateLoad2]
	@pants_id INT,
	@ean VARCHAR(13),
	@fabricator_id INT = 1
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		;
		MERGE Manufactory.EANCode t
		USING (
		      	SELECT	@pants_id pants_id, @fabricator_id fabricator_id
		      ) s
				ON s.pants_id = t.pants_id AND t.fabricator_id = s.fabricator_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	ean = @ean
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pants_id,
		     		ean,
		     		fabricator_id
		     	)
		     VALUES
		     	(
		     		s.pants_id,
		     		@ean,
		     		@fabricator_id
		     	);
		
		UPDATE	Synchro.ProductsForEAN2
		SET 	dt_create = @dt
		WHERE	pants_id = @pants_id
		
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