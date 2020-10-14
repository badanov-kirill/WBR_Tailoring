CREATE PROCEDURE [Material].[RawMaterialIncomeRelation_SetToReserv]
	@doc_id INT,
	@order_detail_xml XML = NULL,
	@order_reserv_xml XML = NULL,
	@rv_bigint VARCHAR(20),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION),
	        @error_text VARCHAR(MAX),
	        @rmods_id TINYINT = 3
	
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
		
	DECLARE @income_output TABLE (rv_bigint VARCHAR(20))
	DECLARE @reserv_output TABLE (rmid_id INT, spcvc_id INT)                	
	
	DECLARE @tab_order_detail AS TABLE 
	        (shkrm_id INT, rmid_id INT, rmod_id INT, okei_id INT, quantity DECIMAL(12, 3), operation_num INT)
	
	DECLARE @tab_order_reserv AS TABLE 
	        (shkrm_id INT, rmid_id INT, rmodr_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(12, 3), operation_num INT)            	
	
	DECLARE @shk_reserv_output TABLE (shkrm_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), rmid_id INT, rmodr_id INT, operation CHAR(1))
		
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте снова.'
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов с кодом ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rm_inc.rmis_id NOT IN (1,2,3,4,5,6) THEN 'Статус документа ' + rmis.rmis_name +  ' не позволяет распределения'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id))v(doc_id,
			doc_type_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id  
			INNER JOIN Material.RawMaterialIncomeStatus rmis
				ON rmis.rmis_id = rm_inc.rmis_id			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) данные не загружены, проверьте файл.', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT @tab_order_detail
	  (
	    shkrm_id,
	    rmid_id,
	    rmod_id,
	    okei_id,
	    quantity,
	    operation_num
	  )
	SELECT	ml.value('@shkrm_id', 'INT')     shkrm_id,
			ml.value('@rmid_id', 'INT')      rmid_id,
			ml.value('@rmod_id', 'INT')      rmod_id,
			ml.value('@okei_id', 'INT')      okei_id,
			ml.value('@quantity', 'DECIMAL(12,3)') quantity,
			ml.value('@op', 'int')           operation_num
	FROM	@order_detail_xml.nodes('items/item')x(ml)
	
	INSERT @tab_order_reserv
	  (
	    shkrm_id,
	    rmid_id,
	    rmodr_id,
	    spcvc_id,
	    okei_id,
	    quantity,
	    operation_num
	  )
	SELECT	ml.value('@shkrm_id', 'INT')     shkrm_id,
			ml.value('@rmid_id', 'INT')      rmid_id,
			ml.value('@rmodr_id', 'INT')     rmodr_id,
			ml.value('@spcvc_id', 'INT')     spcvc_id,
			ml.value('@okei_id', 'INT')      okei_id,
			ml.value('@quantity', 'DECIMAL(12,3)') quantity,
			ml.value('@op', 'int')           operation_num
	FROM	@order_reserv_xml.nodes('items/item')x(ml)
	
	;
	WITH cte AS (
		SELECT	tod.shkrm_id,
				tod.rmid_id
		FROM	@tab_order_detail tod
		UNION 
		SELECT	tor.shkrm_id,
				tor.rmid_id
		FROM	@tab_order_reserv tor
	)
	
	SELECT	@error_text = 'Не найдены следующие ШК:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(c.shkrm_id AS VARCHAR(10)) + CHAR(10)
	      		FROM	cte c   
	      				LEFT JOIN	Material.RawMaterialIncomeDetail rmid
	      					ON	rmid.shkrm_id = c.shkrm_id
	      		WHERE	rmid.rmid_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NULL
	    SELECT	@error_text = 'Не найдены следующие цвето-передачи:' + CHAR(10)
	          	+ (
	          		SELECT	DISTINCT CAST(tor.spcvc_id AS VARCHAR(10)) + CHAR(10)
	          		FROM	@tab_order_reserv tor   
	          				LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
	          					ON	tor.spcvc_id = spcvc.spcvc_id
	          		WHERE	spcvc.spcvc_id IS NULL
	          		FOR XML	PATH('')
	          	)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) обнаружены ошибки.', 16, 1, @error_text)
	    RETURN
	END 	           	
	
	SELECT	@error_text = CASE 
	      	                   WHEN oa_t.qty + ISNULL(oa.qty, 0) > smai.stor_unit_residues_qty THEN 'Сумма резервов на ШК ' + CAST(tor.shkrm_id AS VARCHAR(10)) + 
	      	                        ' превысит актуальный остаток после резервирования.'    
	      	                   ELSE NULL
	      	              END
	FROM	@tab_order_reserv tor   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai   
				ON smai.shkrm_id = tor.shkrm_id
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = tor.shkrm_id
			      			AND	NOT EXISTS (
			      			   		SELECT	1
			      			   		FROM	@tab_order_reserv tor2
			      			   		WHERE	tor2.spcvc_id = smr.spcvc_id
			      			   	)
			      	GROUP BY
			      		smr.shkrm_id
			      ) oa
			OUTER APPLY (
			      	SELECT	SUM(t.quantity) qty
			      	FROM	@tab_order_reserv t
			      	WHERE	t.shkrm_id = tor.shkrm_id
			      	GROUP BY t.shkrm_id
			      ) oa_t
	WHERE oa_t.qty + ISNULL(oa.qty, 0) > smai.stor_unit_residues_qty
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s) обнаружены ошибки.', 16, 1, @error_text)
	    RETURN
	END 	
	
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Material.RawMaterialIncome
		SET 	employee_id = @employee_id,
				dt = @dt
				OUTPUT	CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(20))
				INTO	@income_output (
						rv_bigint
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
		
		DELETE	Material.RawMaterialIncomeOrderRelationDetail
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
		
		DELETE	Material.RawMaterialIncomeOrderReservRelationDetail
		      	OUTPUT	DELETED.rmid_id,
		      			DELETED.spcvc_id
		      	INTO	@reserv_output (
		      			rmid_id,
		      			spcvc_id
		      		)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
		
		DELETE	srmr
		      	OUTPUT	DELETED.shkrm_id,
		      			DELETED.spcvc_id,
		      			DELETED.okei_id,
		      			DELETED.quantity,
		      			@dt,
		      			@employee_id,
		      			DELETED.rmid_id,
		      			DELETED.rmodr_id,
		      			@proc_id,
		      			'D'
		      	INTO	History.SHKRawMaterialReserv (
		      			shkrm_id,
		      			spcvc_id,
		      			okei_id,
		      			quantity,
		      			dt,
		      			employee_id,
		      			rmid_id,
		      			rmodr_id,
		      			proc_id,
		      			operation
		      		)
		FROM	Warehouse.SHKRawMaterialReserv srmr   
				INNER JOIN	@reserv_output ro   
				INNER JOIN	Material.RawMaterialIncomeDetail rmid
					ON	rmid.rmid_id = ro.rmid_id
					ON	rmid.shkrm_id = srmr.shkrm_id
					AND	ro.spcvc_id = srmr.spcvc_id
		
		INSERT Material.RawMaterialIncomeOrderRelationDetail
		  (
		    rmid_id,
		    rmod_id,
		    okei_id,
		    quantity,
		    doc_id,
		    doc_type_id,
		    operation_num
		  )
		SELECT	tod.rmid_id,
				tod.rmod_id,
				tod.okei_id,
				tod.quantity,
				@doc_id               doc_id,
				@doc_type_id          doc_type_id,
				tod.operation_num
		FROM	@tab_order_detail     tod
		
		INSERT Material.RawMaterialIncomeOrderReservRelationDetail
		  (
		    rmid_id,
		    rmodr_id,
		    spcvc_id,
		    okei_id,
		    quantity,
		    doc_id,
		    doc_type_id,
		    operation_num
		  )
		SELECT	rmid_id,
				rmodr_id,
				spcvc_id,
				okei_id,
				quantity,
				@doc_id               doc_id,
				@doc_type_id          doc_type_id,
				tor.operation_num
		FROM	@tab_order_reserv     tor;
		
		MERGE Warehouse.SHKRawMaterialReserv t
		USING (
		      	SELECT	tor.shkrm_id,
		      			tor.spcvc_id,
		      			tor.rmid_id,
		      			tor.rmodr_id,
		      			tor.okei_id,
		      			tor.quantity
		      	FROM	@tab_order_reserv tor   
		      			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
		      				ON	smai.shkrm_id = tor.shkrm_id
		      ) s
				ON t.shkrm_id = s.shkrm_id
				AND t.spcvc_id = s.spcvc_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.quantity = t.quantity + s.quantity,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		shkrm_id,
		     		spcvc_id,
		     		okei_id,
		     		quantity,
		     		dt,
		     		employee_id,
		     		rmid_id,
		     		rmodr_id
		     	)
		     VALUES
		     	(
		     		s.shkrm_id,
		     		s.spcvc_id,
		     		s.okei_id,
		     		s.quantity,
		     		@dt,
		     		@employee_id,
		     		s.rmid_id,
		     		s.rmodr_id
		     	)
		     OUTPUT	INSERTED.shkrm_id,
		     		INSERTED.spcvc_id,
		     		INSERTED.okei_id,
		     		INSERTED.quantity,
		     		INSERTED.rmid_id,
		     		INSERTED.rmodr_id,
		     		UPPER(LEFT($action, 1))
		     INTO	@shk_reserv_output (
		     		shkrm_id,
		     		spcvc_id,
		     		okei_id,
		     		quantity,
		     		rmid_id,
		     		rmodr_id,
		     		operation
		     	);
		     	
			IF EXISTS (
		   	SELECT	1
		   	FROM	Warehouse.SHKRawMaterialActualInfo smai
		   	WHERE	EXISTS(
		   	     		SELECT	1
		   	     		FROM	@tab_order_reserv tor
		   	     		WHERE	tor.shkrm_id = smai.shkrm_id
		   	     	)
		   			AND	EXISTS (
		   			   		SELECT	1
		   			   		FROM	Warehouse.SHKRawMaterialReserv smr
		   			   		WHERE	smr.shkrm_id = smai.shkrm_id
		   			   		HAVING
		   			   			SUM(smr.quantity) > smai.stor_unit_residues_qty
		   			   	)
		)
		BEGIN
		    RAISERROR('Возникло превышение резервов, обновите данные и попробуйте ещё раз', 16, 1)
		    RETURN
		END
		
		INSERT INTO History.SHKRawMaterialReserv
		  (
		    shkrm_id,
		    spcvc_id,
		    okei_id,
		    quantity,
		    dt,
		    employee_id,
		    rmid_id,
		    rmodr_id,
		    proc_id,
		    operation
		  )
		SELECT	sro.shkrm_id,
				sro.spcvc_id,
				sro.okei_id,
				sro.quantity,
				@dt,
				@employee_id,
				sro.rmid_id,
				sro.rmodr_id,
				@proc_id,
				sro.operation
		FROM	@shk_reserv_output sro
				
		COMMIT TRANSACTION
		
		SELECT	rv_bigint
		FROM	@income_output
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