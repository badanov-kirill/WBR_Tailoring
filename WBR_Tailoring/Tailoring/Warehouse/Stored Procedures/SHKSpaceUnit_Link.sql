CREATE PROCEDURE [Warehouse].[SHKSpaceUnit_Link]
	@shksu_id INT,
	@doc_id INT,
	@employee_id INT,
	@su_id INT,
	@qty SMALLINT
AS
	SET NOCOUNT ON
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @with_log BIT = 1
	DECLARE @doc_type_id TINYINT = 1
	
	DECLARE @rmi_status_create TINYINT = 1 --Создан
	DECLARE @rmi_status_allow_accept TINYINT = 2 -- Разрешена приемка
	DECLARE @rmi_status_unload TINYINT = 3 --Разгрузка
	DECLARE @rmi_status_accept TINYINT = 4 -- Приемка
	
	SELECT	@error_text = CASE 
	      	                   WHEN su.shksu_id IS NULL THEN 'Некорректный ШК ' + CAST(v.shksu_id AS VARCHAR(10))
	      	                   WHEN su.doc_id IS NOT NULL THEN 'ШК ' + CAST(v.shksu_id AS VARCHAR(10)) + ' уже привязан к документу № ' + CAST(su.doc_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shksu_id))v(shksu_id)   
			LEFT JOIN	Warehouse.SHKSpaceUnit su
				ON	su.shksu_id = v.shksu_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.doc_id IS NULL THEN 'Документа с номером ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmi.rmis_id NOT IN (@rmi_status_create, @rmi_status_accept, @rmi_status_unload, @rmi_status_accept, @rmi_status_allow_accept) THEN 
	      	                        'Документ находится в статусе ' +
	      	                        rmis.rmis_name + ' привязывать грузовые места нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@doc_id))v(doc_id)   
			LEFT JOIN	Material.RawMaterialIncome rmi   
			INNER JOIN	Material.RawMaterialIncomeStatus rmis
				ON	rmis.rmis_id = rmi.rmis_id
				ON	rmi.doc_id = v.doc_id
				AND	rmi.doc_type_id = @doc_type_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Warehouse.SHKSpaceUnit
		SET 	doc_id = @doc_id,
				doc_type_id = @doc_type_id,
				su_id = @su_id,
				quantity = @qty
		WHERE	shksu_id = @shksu_id
				AND	doc_id IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто-то до вас успел привязять данный шк', 16, 1);
		    RETURN
		END
		
		UPDATE	Material.RawMaterialIncome
		SET 	rmis_id         = @rmi_status_unload,
				dt              = @dt,
				employee_id     = @employee_id
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
				AND	rmis_id IN (@rmi_status_create, @rmi_status_allow_accept)
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 