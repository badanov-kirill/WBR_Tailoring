CREATE PROCEDURE [Ozon].[SubjectsCategories_Set]
	@data Ozon.SubjectsCategoriesType READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	
		FROM	Ozon.SubjectsCategories
		
		INSERT INTO Ozon.SubjectsCategories
			(
				subject_id,
				category_id,
				dt,
				employee_id
			)
		SELECT	d.subject_id,
				d.category_id,
				@dt,
				@employee_id
		FROM	@data d
		
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
