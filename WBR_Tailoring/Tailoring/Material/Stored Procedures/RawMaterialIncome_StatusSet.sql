CREATE PROCEDURE [Material].[RawMaterialIncome_StatusSet]
	@doc_id INT,
	@state_dst_id INT,
	@employee_id INT,
	@no_check BIT = 0
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @doc_type_id TINYINT = 1
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rmi.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN @no_check = 0 AND rmisg.rmis_src_id IS NULL THEN 'Запрещен переход в статус ' + rmisd.rmis_name + ' из текущего статуса ' + rmis.rmis_name
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rmi   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id   
			LEFT JOIN	Material.RawMaterialIncomeStatusGraph rmisg
				ON	rmisg.rmis_src_id = rmi.rmis_id
				AND	rmisg.rmis_dst_id = @state_dst_id
				ON	rmi.doc_id = v.doc_id
				AND	rmi.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialIncomeStatus rmisd
				ON	rmisd.rmis_id = @state_dst_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		UPDATE	rmi
		SET 	rmis_id = @state_dst_id,
				dt = @dt,
				employee_id = @employee_id
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
		FROM	Material.RawMaterialIncome rmi
				LEFT JOIN	Material.RawMaterialIncomeStatusGraph rmisg
					ON	rmi.rmis_id = rmisg.rmis_src_id
					AND	rmisg.rmis_dst_id = @state_dst_id
		WHERE rmi.doc_id = @doc_id AND rmi.doc_type_id = @doc_type_id AND (rmisg.rmis_src_id IS NOT NULL OR @no_check = 1)
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Не удалось обновить статус, возможно его кто-то уже поменял', 16, 1)
		    RETURN
		END
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