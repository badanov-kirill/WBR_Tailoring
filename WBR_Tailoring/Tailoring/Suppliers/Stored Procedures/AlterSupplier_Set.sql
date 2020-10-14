CREATE PROCEDURE [Suppliers].[AlterSupplier_Set]
	@alter_supplier_id INT = NULL,
	@alter_supplier_name VARCHAR(100),
	@label_info VARCHAR(500),
	@is_deleted BIT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF @alter_supplier_id IS NOT NULL
	   AND NOT EXISTS (
	       	SELECT	1
	       	FROM	Suppliers.AlterSupplier as1
	       	WHERE	as1.alter_supplier_id = @alter_supplier_id
	       )
	BEGIN
	    RAISERROR('Поставщика с кодом %d не существует', 16, 1, @alter_supplier_id)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Suppliers.AlterSupplier as1
	   	WHERE	(@alter_supplier_id IS NULL OR as1.alter_supplier_id != @alter_supplier_id)
	   			AND	as1.alter_supplier_name = @alter_supplier_name
	   			AND	as1.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Поставщик с наименованием (%s) уже существует', 16, 1, @alter_supplier_name)
	    RETURN
	END
	
	BEGIN TRY
		;
		MERGE Suppliers.AlterSupplier t
		USING (
		      	SELECT	@alter_supplier_id alter_supplier_id,
		      			@alter_supplier_name alter_supplier_name,
		      			@label_info      label_info,
		      			@dt              dt,
		      			@employee_id     employee_id,
		      			@is_deleted      is_deleted
		      ) s
				ON t.alter_supplier_id = s.alter_supplier_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	alter_supplier_name     = s.alter_supplier_name,
		     		label_info              = s.label_info,
		     		employee_id             = s.employee_id,
		     		dt                      = @dt,
		     		is_deleted              = s.is_deleted
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		alter_supplier_name,
		     		is_deleted,
		     		label_info,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.alter_supplier_name,
		     		s.is_deleted,
		     		s.label_info,
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