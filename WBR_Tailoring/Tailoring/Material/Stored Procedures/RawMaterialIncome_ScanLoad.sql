CREATE PROCEDURE [Material].[RawMaterialIncome_ScanLoad]
	@doc_id INT,
	@employee_id INT,
	@scan_load BIT
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @doc_type_id TINYINT = 1	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmi.is_deleted = 1 THEN 'Поступление удалено'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rmi
				ON	rmi.doc_id = v.doc_id
				AND	rmi.doc_type_id = v.doc_type_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Material.RawMaterialIncome
		SET 	dt               = @dt,
				employee_id      = @employee_id,
				scan_load_dt     = CASE 
				                    WHEN @scan_load = 1 THEN @dt
				                    ELSE NULL
				               END
				OUTPUT	INSERTED.doc_id,
						INSERTED.doc_type_id,
						INSERTED.rmis_id,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.supplier_id,
						INSERTED.suppliercontract_id,
						INSERTED.supply_dt,
						INSERTED.is_deleted,
						INSERTED.goods_dt,
						INSERTED.comment,
						INSERTED.payment_comment,
						INSERTED.plan_sum,
						INSERTED.scan_load_dt
				INTO	History.RawMaterialIncome (
						doc_id,
						doc_type_id,
						rmis_id,
						dt,
						employee_id,
						supplier_id,
						suppliercontract_id,
						supply_dt,
						is_deleted,
						goods_dt,
						comment,
						payment_comment,
						plan_sum,
						scan_load_dt
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
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