CREATE PROCEDURE [Products].[SketchBranchOfficePattern_Set]
	@sketch_id INT,
	@tab_office dbo.List READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.Sketch s
	   		   	WHERE	s.sketch_id = @sketch_id
	   )
	BEGIN
	    RAISERROR('Эскиза с кодом %d не существует', 16, 1, @sketch_id)
	    RETURN
	END
	
	BEGIN TRY
		;
		WITH cte_target AS
			(
				SELECT	pop.sketch_id,
						pop.office_id,
						pop.employee_id,
						pop.dt
				FROM	Products.SketchBranchOfficePattern pop
				WHERE	pop.sketch_id = @sketch_id
			)
		MERGE cte_target t
		USING @tab_office s
				ON s.id = t.office_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		office_id,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		@sketch_id,
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