CREATE PROCEDURE [Material].[RawMaterialIncomeStatus_Set]
	@rmis_id INT,
	@rmis_name VARCHAR(50),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialIncomeStatus rmis
	   	WHERE	rmis.rmis_name = @rmis_name
	   			AND	rmis.rmis_id != @rmis_id
	   )
	BEGIN
	    RAISERROR('Такое наименование уже используется', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Material.RawMaterialIncomeStatus t
		USING (
		      	SELECT	@rmis_id         rmis_id,
		      			@rmis_name       rmis_name,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.rmis_id = t.rmis_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	rmis_name       = s.rmis_name,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		rmis_id,
		     		rmis_name,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.rmis_id,
		     		s.rmis_name,
		     		s.dt,
		     		s.employee_id
		     	)
		     OUTPUT	INSERTED.rmis_id,
		     		INSERTED.rmis_name,
		     		INSERTED.dt,
		     		INSERTED.employee_id
		     INTO	History.RawMaterialIncomeStatus (
		     		rmis_id,
		     		rmis_name,
		     		dt,
		     		employee_id
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