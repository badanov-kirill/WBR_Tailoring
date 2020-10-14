CREATE PROCEDURE [Products].[Sketch_SpecificationSet]
	@sketch_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Sketch s
	   	WHERE	s.sketch_id = @sketch_id
	   )
	BEGIN
	    RAISERROR('Эскиза с номером %d не существует', 16, 1, @sketch_id)
	    RETURN
	END	
	
	BEGIN TRY
		UPDATE	Products.Sketch
		SET 	specification_dt = @dt,
				specification_employee_id = @employee_id
				OUTPUT	INSERTED.sketch_id,
						INSERTED.specification_dt,
						INSERTED.specification_employee_id
				INTO	History.SketchSpecification (
						sketch_id,
						specification_dt,
						specification_employee_id
					)
		WHERE	sketch_id = @sketch_id
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