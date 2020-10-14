CREATE PROCEDURE [Material].[RawMaterialIncomeSpaceUnit_Set]
	@doc_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	--DECLARE @dt dbo.SECONDSTIME = GETDATE()
	--DECLARE @doc_type_id TINYINT = 1
	--DECLARE @error_text VARCHAR(MAX)
	--DECLARE @data_tab TABLE (su_id INT, quantity SMALLINT) 
	--DECLARE @state_dst_id INT = 3 --Разгрузка
	
	
	--SELECT	@error_text = CASE 
	--      	                   WHEN rmi.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	--      	                   WHEN rmi.is_deleted = 1 THEN 'Поступление материалов удалено'
	--      	                   WHEN rmisg.rmis_src_id IS NULL THEN 'Запрещен переход в статус ' + rmisd.rmis_name + ' из текущего статуса ' + rmis.rmis_name
	--      	                   ELSE NULL
	--      	              END
	--FROM	(VALUES(@doc_id,
	--		@doc_type_id))v(doc_id,
	--		doc_type_id)   
	--		LEFT JOIN	Material.RawMaterialIncome rmi   
	--		INNER JOIN	Material.RawMaterialIncomeStatus rmis
	--			ON	rmis.rmis_id = rmi.rmis_id   
	--		LEFT JOIN	Material.RawMaterialIncomeStatusGraph rmisg
	--			ON	rmisg.rmis_src_id = rmi.rmis_id
	--			AND	rmisg.rmis_dst_id = @state_dst_id
	--			ON	rmi.doc_id = v.doc_id
	--			AND	rmi.doc_type_id = v.doc_type_id   
	--		LEFT JOIN	Material.RawMaterialIncomeStatus rmisd
	--			ON	rmisd.rmis_id = @state_dst_id
	
	--IF @error_text IS NOT NULL
	--BEGIN
	--    RAISERROR('%s', 16, 1, @error_text)
	--    RETURN
	--END
	
	--INSERT INTO @data_tab
	--	(
	--		su_id,
	--		quantity
	--	)
	--SELECT	ml.value('@id', 'int')           su_id,
	--		ml.value('@qty', 'smallint')     quantity
	--FROM	@data_xml.nodes('root/su')x(ml)
	
	--SELECT	@error_text = CASE 
	--      	                   WHEN su.su_id IS NULL THEN 'Еденицы места с кодом ' + CAST(dt.su_id AS VARCHAR(10)) + ' не существует'
	--      	                   WHEN oa.cnt > 1 THEN 'Еденица места ' + ISNULL(su.su_name, '') + ' указана более одного раза'
	--      	                   ELSE NULL
	--      	              END
	--FROM	@data_tab dt   
	--		LEFT JOIN	RefBook.SpaceUnit su
	--			ON	su.su_id = dt.su_id   
	--		OUTER APPLY (
	--		      	SELECT	COUNT(*)      cnt
	--		      	FROM	@data_tab     dtoa
	--		      	WHERE	dtoa.su_id = dt.su_id
	--		      ) oa
	--WHERE	oa.cnt > 1
	--		OR	su.su_id IS NULL
	
	--IF @error_text IS NOT NULL
	--BEGIN
	--    RAISERROR('%s', 16, 1, @error_text)
	--    RETURN
	--END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		--UPDATE	rmi
		--SET 	rmis_id = @state_dst_id,
		--		dt = @dt,
		--		employee_id = @employee_id
		--		OUTPUT	INSERTED.doc_id,
		--				INSERTED.doc_type_id,
		--				INSERTED.rmis_id,
		--				INSERTED.dt,
		--				INSERTED.employee_id,
		--				INSERTED.supplier_id,
		--				INSERTED.suppliercontract_id,
		--				INSERTED.supply_dt,
		--				INSERTED.is_deleted,
		--				INSERTED.goods_dt,
		--				INSERTED.comment,
		--				INSERTED.payment_comment,
		--				INSERTED.plan_sum,
		--				INSERTED.scan_load_dt
		--		INTO	History.RawMaterialIncome (
		--				doc_id,
		--				doc_type_id,
		--				rmis_id,
		--				dt,
		--				employee_id,
		--				supplier_id,
		--				suppliercontract_id,
		--				supply_dt,
		--				is_deleted,
		--				goods_dt,
		--				comment,
		--				payment_comment,
		--				plan_sum,
		--				scan_load_dt
		--			)
		--FROM	Material.RawMaterialIncome rmi
		--		INNER JOIN	Material.RawMaterialIncomeStatusGraph rmisg
		--			ON	rmi.rmis_id = rmisg.rmis_src_id
		--			AND	rmisg.rmis_dst_id = @state_dst_id
		
		--IF @@ROWCOUNT = 0
		--BEGIN
		--    RAISERROR('Не удалось обновить статус, возможно его кто-то уже поменял', 16, 1)
		--    RETURN
		--END
		
		--;
		--WITH cte_Target AS
		--	(
		--		SELECT	rmisu.doc_id,
		--				rmisu.doc_type_id,
		--				rmisu.su_id,
		--				rmisu.quantity,
		--				rmisu.dt,
		--				rmisu.employee_id
		--		FROM	Material.RawMaterialIncomeSpaceUnit rmisu
		--		WHERE	rmisu.doc_id = @doc_id
		--				AND	rmisu.doc_type_id = @doc_type_id
		--	)
		--MERGE cte_Target t
		--USING @data_tab s
		--		ON s.su_id = t.su_id
		--WHEN  MATCHED  THEN 
		--     UPDATE	
		--     SET 	quantity        = s.quantity,
		--     		dt              = @dt,
		--     		employee_id     = @employee_id
		--WHEN NOT MATCHED BY TARGET THEN 
		--     INSERT
		--     	(
		--     		doc_id,
		--     		doc_type_id,
		--     		su_id,
		--     		quantity,
		--     		dt,
		--     		employee_id
		--     	)
		--     VALUES
		--     	(
		--     		@doc_id,
		--     		@doc_type_id,
		--     		s.su_id,
		--     		s.quantity,
		--     		@dt,
		--     		@employee_id
		--     	)
		--WHEN NOT MATCHED BY SOURCE THEN 
		--     DELETE	;
		
		
		COMMIT TRANSACTION
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