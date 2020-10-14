CREATE PROCEDURE [Warehouse].[SHKRawMaterial_ReservUpd]
	@spcvc_id INT,
	@shkrm_id INT,
	@qty DECIMAL(9, 3),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rmt_id INT
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	IF @qty <= 0
	BEGIN
	    RAISERROR('Неверное количество резерва', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = v.spcvc_id   
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   WHEN smai.rmt_id != @rmt_id THEN 'В выбранных шк, есть не подходящие по типу материала'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не имеет статуса'
	      	                   WHEN smai.stor_unit_residues_qty - ISNULL(oa.res_qty, 0) < @qty THEN 'Недостаточно остатка по шк' + CAST(dt.shkrm_id AS VARCHAR(10)) 
	      	                   + ' Остаток: ' + CAST(smai.stor_unit_residues_qty AS VARCHAR(10)) + ' , резервы: ' + CAST(ISNULL(oa.res_qty, 0) AS VARCHAR(10)) 
	      	                   + ' потребность: ' + CAST(@qty AS VARCHAR(10))
	      	                   WHEN shkmr.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' не зарезервирован под этот элемент комплектации.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))dt(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialReserv shkmr
				ON	shkmr.shkrm_id = sm.shkrm_id
				AND	shkmr.spcvc_id = @spcvc_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) res_qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = sm.shkrm_id
			      			AND	smr.spcvc_id != @spcvc_id
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	smr
		SET 	quantity = @qty
		    	OUTPUT	INSERTED.shkrm_id,
		    			INSERTED.spcvc_id,
		    			INSERTED.okei_id,
		    			INSERTED.quantity,
		    			@dt,
		    			@employee_id,
		    			INSERTED.rmid_id,
		    			INSERTED.rmodr_id,
		    			@proc_id,
		    			'U'
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
		FROM	Warehouse.SHKRawMaterialReserv smr
				INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
					ON	smai.shkrm_id = smr.shkrm_id
				OUTER APPLY (
				      	SELECT	SUM(smro.quantity) qty
				      	FROM	Warehouse.SHKRawMaterialReserv smro
				      	WHERE	smro.shkrm_id = smr.shkrm_id
				      			AND	smro.spcvc_id != @spcvc_id
				      ) oar
		WHERE	smr.shkrm_id = @shkrm_id
				AND	smr.spcvc_id = @spcvc_id
				AND	smai.stor_unit_residues_qty - ISNULL(oar.qty, 0) >= @qty
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Не хватило свободного остатка, обновите данные и попробуйте подобрать другой ШК', 16, 1)
		    RETURN
		END
		
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 