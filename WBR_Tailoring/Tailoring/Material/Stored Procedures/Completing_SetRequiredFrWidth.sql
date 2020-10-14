CREATE PROCEDURE [Material].[Completing_SetRequiredFrWidth]
	@completing_id INT,
	@required_frame_width BIT
AS
	SET NOCOUNT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.Completing c
	   	WHERE	c.completing_id = @completing_id
	   )
	BEGIN
	    RAISERROR('Комплектации с кодом %d не существует', 16, 1, @completing_id)
	    RETURN
	END
	
	BEGIN TRY
	
		UPDATE	c
		SET 	c.required_frame_width = @required_frame_width
		FROM	Material.Completing c
		WHERE	c.completing_id = @completing_id
		
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