CREATE PROCEDURE [Planing].[SketchPrePlanComment_Del]
	@spp_id INT,
	@employee_id INT,
	@dt DATETIME2(0)
AS
	SET NOCOUNT ON
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.SketchPrePlanComment sppc
	   	WHERE	sppc.spp_id = @spp_id
	   			AND	sppc.dt = @dt
	   			AND	sppc.employee_id = @employee_id
	   )
	BEGIN
	    RAISERROR('Такого коммента нет', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	sppc
		FROM	Planing.SketchPrePlanComment sppc
		WHERE	sppc.spp_id = @spp_id
				AND	sppc.dt = @dt
				AND	sppc.employee_id = @employee_id
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
	