CREATE PROCEDURE [Ozon].[Categoryes_Set]
	@data Ozon.CategoryesType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Ozon.Categories t
		USING @data s
				ON t.category_id = s.category_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.caregory_parrent_id = s.caregory_parrent_id,
		     		t.category_name = s.category_name,
		     		t.dt = @dt,
		     		t.is_deleted = 0
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		category_id,
		     		caregory_parrent_id,
		     		category_name,
		     		is_deleted,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.category_id,
		     		s.caregory_parrent_id,
		     		s.category_name,
		     		0,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	t.dt = @dt,
		     		t.is_deleted = 0;
		
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
