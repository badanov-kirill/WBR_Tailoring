CREATE PROCEDURE [Products].[SketchOldBranchOfficePattern_Set]
	@so_id INT,
	@tab_office dbo.List READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.SketchOld so
	   	WHERE	so.so_id = @so_id
	   )
	BEGIN
	    RAISERROR('Эскиза с кодом %d не существует', 16, 1, @so_id)
	    RETURN
	END
	
	BEGIN TRY
		;
		WITH cte_target AS
			(
				SELECT	sop.so_id,
						sop.office_id,
						sop.employee_id,
						sop.dt
				FROM	Products.SketchOldBranchOfficePattern sop
				WHERE	sop.so_id = @so_id
			)
		MERGE cte_target t
		USING @tab_office s
				ON s.id = t.office_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		so_id,
		     		office_id,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		@so_id,
		     		s.id,
		     		@employee_id,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		     
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