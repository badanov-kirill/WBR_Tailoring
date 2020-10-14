CREATE PROCEDURE [Material].[Cloth_Set]
	@cloth_id INT = NULL,
	@ct_id INT,
	@cloth_name VARCHAR(50),
	@employee_id INT,
	@is_deleted BIT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Material.Cloth c
	   	WHERE	c.cloth_name = @cloth_name
	   			AND	(c.ct_id = @ct_id)
	   			AND	c.cloth_id != @cloth_id
	   )
	BEGIN
	    RAISERROR('Такое наименование уже используется', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Material.Cloth t
		USING (
		      	SELECT	@cloth_id        cloth_id,
		      			@ct_id           ct_id,
		      			@cloth_name      cloth_name,
		      			@is_deleted      is_deleted,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.cloth_id = t.cloth_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	cloth_name      = s.cloth_name,
		     		ct_id           = s.ct_id,
		     		is_deleted      = s.is_deleted,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		cloth_name,
		     		is_deleted,
		     		employee_id,
		     		dt,
		     		ct_id
		     	)
		     VALUES
		     	(
		     		s.cloth_name,
		     		s.is_deleted,
		     		s.employee_id,
		     		s.dt,
		     		s.ct_id
		     	);
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