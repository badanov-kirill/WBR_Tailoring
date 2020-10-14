CREATE PROCEDURE [Suppliers].[RawMaterialRefundStatus_Set]
	@rmrs_id INT,
	@rmrs_name VARCHAR(50),
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Suppliers.RawMaterialRefundStatus rmrs
	   	WHERE	rmrs.rmrs_name = @rmrs_name
	   			AND	rmrs.rmrs_id != @rmrs_id
	   )
	BEGIN
	    RAISERROR('Такое наименование уже используется', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		MERGE Suppliers.RawMaterialRefundStatus t
		USING (
		      	SELECT	@rmrs_id         rmrs_id,
		      			@rmrs_name       rmrs_name,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON s.rmrs_id = t.rmrs_id
		WHEN  MATCHED  THEN 
		     UPDATE	
		     SET 	rmrs_name       = s.rmrs_name,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED  THEN 
		     INSERT
		     	(
		     		rmrs_id,
		     		rmrs_name,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.rmrs_id,
		     		s.rmrs_name,
		     		s.dt,
		     		s.employee_id
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
GO