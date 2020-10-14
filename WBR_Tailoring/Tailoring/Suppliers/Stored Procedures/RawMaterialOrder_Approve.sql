CREATE PROCEDURE [Suppliers].[RawMaterialOrder_Approve]
	@rmo_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmo.rmo_id IS NULL THEN 'Заказа поставщику с номером ' + CAST(v.rmo_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmo.is_deleted = 1 THEN 'Документ удален'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmo_id))v(rmo_id)   
			LEFT JOIN	Suppliers.RawMaterialOrder rmo
				ON	rmo.rmo_id = v.rmo_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Suppliers.RawMaterialOrder
		SET 	approve_dt              = @dt,
				approve_employee_id     = @employee_id,
				employee_id             = @employee_id,
				dt                      = @dt
		WHERE	rmo_id                  = @rmo_id
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
