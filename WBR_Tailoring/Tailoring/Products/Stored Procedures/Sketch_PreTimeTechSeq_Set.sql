CREATE PROCEDURE [Products].[Sketch_PreTimeTechSeq_Set]
	@sketch_id INT,
	@pre_time_tech_seq INT,
	@employee_id INT,
	@loops TINYINT = NULL,
	@buttons TINYINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
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
		BEGIN TRANSACTION 
		
		UPDATE	Products.Sketch
		SET 	pre_time_tech_seq = @pre_time_tech_seq,
				dt = @dt,
				employee_id = @employee_id,
				loops = @loops,
				buttons = @buttons
		WHERE	sketch_id = @sketch_id 
		
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