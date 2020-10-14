CREATE PROCEDURE [Logistics].[Vehicle_Add]
	@brand_name VARCHAR(50),
	@number_plate VARCHAR(9),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	BEGIN TRY
		;
		MERGE Logistics.Vehicle t
		USING (
		      	SELECT	@number_plate     number_plate,
		      			@brand_name       brand_name,
		      			@employee_id      employee_id,
		      			@dt               dt
		      ) s
				ON t.number_plate = s.number_plate
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	brand_name      = s.brand_name,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		brand_name,
		     		number_plate,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.brand_name,
		     		s.number_plate,
		     		s.dt,
		     		s.employee_id
		     	) 
		     OUTPUT	INSERTED.vehicle_id;
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
