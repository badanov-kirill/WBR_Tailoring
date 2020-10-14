CREATE PROCEDURE [Warehouse].[SHKRawMaterial_ReservConfekcioner]
	@spcvc_id INT,
	@employee_id INT,
	@data_xml XML,
	@qty DECIMAL(9, 3)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @qty_need DECIMAL(9, 3)
	DECLARE @qty_res DECIMAL(9, 3)
	DECLARE @rmt_id INT
	DECLARE @okei_id INT
	DECLARE @reserv_output TABLE (shkrm_id INT, spcvc_id INT, okei_id INT, quantity DECIMAL(9, 3), rmid_id INT, rmodr_id INT)
	DECLARE @shkrm_id INT
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT	
	DECLARE @check_frame_width BIT
	DECLARE @frame_width_completing SMALLINT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	DECLARE @data_tab TABLE (shkrm_id INT)
	
	IF @qty <= 0
	BEGIN
	    RAISERROR('Резервируемое количество должно быть больше нуля.', 16, 1)
	    RETURN
	END 
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Строчки комплектации изделия с кодом ' + CAST(v.spcvc_id AS VARCHAR(10)) + ' не существует.'
	      	                        --WHEN spcvc.cs_id != @cvc_state_need_proc THEN 'Строчка комплектации изделия находится в статусе ' + cs.cs_name +
	      	                        --     ', резервирование со склада запрещено.'
	      	                        --WHEN oar.is_reserv IS NOT NULL THEN 'Строчка комплектации изделия уже имеет резерв.'
	      	                   WHEN @qty IS NULL AND ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) <= 0 THEN 
	      	                        'Количество необходимого материала должно быть больше 0.'
	      	                   WHEN @qty IS NULL AND ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) <= ISNULL(oar.qty, 0) THEN 
	      	                        'Текущие резервы уже перекрывают потребность'
	      	                   ELSE NULL
	      	              END,
			@qty_need     = ISNULL(@qty, ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) - ISNULL(oar.qty, 0)),
			@qty_res      = ISNULL(@qty, ISNULL(oa_lay.consumption, spcvc.consumption) * ISNULL(spcv.corrected_qty, spcv.qty) - ISNULL(oar.qty, 0)),
			@rmt_id       = spcvc.rmt_id,
			@okei_id      = spcvc.okei_id,
			@check_frame_width = c.check_frame_width,
			@frame_width_completing = ISNULL(spcvc.frame_width, 0)
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc   
			INNER JOIN Material.Completing c
				ON c.completing_id = spcvc.completing_id
			INNER JOIN	Planing.CompletingStatus cs
				ON	cs.cs_id = spcvc.cs_id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id
				ON	spcvc.spcvc_id = v.spcvc_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.spcvc_id = v.spcvc_id
			      ) oar
			OUTER APPLY (SELECT	TOP(1) l.frame_width, tl.tl_id
					FROM	Manufactory.TaskLayout tl   
							INNER JOIN	Manufactory.TaskLayoutDetail tld
								ON	tld.tl_id = tl.tl_id   
							INNER JOIN	Manufactory.Layout l
								ON	l.layout_id = tld.layout_id
					WHERE	tl.spcv_id = spcv.spcv_id
							AND	l.base_completing_id = spcvc.completing_id
							AND	l.base_completing_number = spcvc.completing_number
							AND	l.is_deleted = 0
					ORDER BY
						tl.tl_id DESC, l.frame_width ASC) oa_lay_fw
			OUTER APPLY (
					SELECT	AVG(l.base_consumption) consumption
					FROM	Manufactory.TaskLayout tl   
							INNER JOIN	Manufactory.TaskLayoutDetail tld
								ON	tld.tl_id = tl.tl_id   
							INNER JOIN	Manufactory.Layout l
								ON	l.layout_id = tld.layout_id
					WHERE	tl.spcv_id = spcv.spcv_id
							AND	l.base_completing_id = spcvc.completing_id
							AND	l.base_completing_number = spcvc.completing_number
							AND	l.is_deleted = 0
							AND l.frame_width = oa_lay_fw.frame_width
							AND tl.tl_id = oa_lay_fw.tl_id
			) oa_lay
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			shkrm_id
		)
	SELECT	ml.value('@shkrm[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                        --WHEN smai.rmt_id != @rmt_id THEN 'В выбранных шк, есть не подходящие по типу материала'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не имеет статуса'
	      	                   WHEN sms.state_id NOT IN (3) THEN 'ШК в статусе ' + smsd.state_name + ', резервировать нельзя.'
	      	                   WHEN smai.stor_unit_residues_okei_id != @okei_id THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' имеет еденицу хранения остатков, отличную от потребности'
	      	                   WHEN smr.shkrm_id IS NOT NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' уже использован для резерва на эту комплектацию.'
	      	                   WHEN @check_frame_width = 1 AND ISNULL(smai.frame_width, 0) != @frame_width_completing THEN 
	      	                   		'У ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' шир.дл.диам. (' + CAST(ISNULL(smai.frame_width, 0) AS VARCHAR(10)) + ') не совпадает с комплектацией(' 
	      	                   		+ CAST(ISNULL(@frame_width_completing, 0) AS VARCHAR(10)) + ')'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.shkrm_id = smai.shkrm_id
				AND	smr.spcvc_id = @spcvc_id
	WHERE	sm.shkrm_id IS NULL
			OR	smai.shkrm_id IS NULL
			  	--OR	smai.rmt_id != @rmt_id
			OR	sms.shkrm_id IS NULL
			OR	sms.state_id NOT IN (3)
			OR	smai.stor_unit_residues_okei_id != @okei_id
			OR	smr.shkrm_id IS NOT NULL
			OR  (@check_frame_width = 1 AND ISNULL(smai.frame_width, 0) != @frame_width_completing)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN SUM(smai.stor_unit_residues_qty) <= SUM(oa.qty) THEN 'Выбранные ШК не имеют свободного остатка'
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) THEN 'Остатка по выбранным ШК ' + CAST(SUM(smai.stor_unit_residues_qty) AS VARCHAR(10)) 
	      	                        +
	      	                        ' не хватает для покрытия потребности ' +
	      	                        CAST(@qty_need AS VARCHAR(10))
	      	                   WHEN @qty_need > SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0) THEN 'Свободного остатка, по выбранным ШК ' + CAST((SUM(smai.stor_unit_residues_qty) - ISNULL(SUM(oa.qty), 0)) AS VARCHAR(10)) 
	      	                        +
	      	                        ', не хватает для покрытия потребности ' + CAST(@qty_need AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = dt.shkrm_id   
			OUTER APPLY (
			      	SELECT	SUM(smr.quantity) qty
			      	FROM	Warehouse.SHKRawMaterialReserv smr
			      	WHERE	smr.shkrm_id = smai.shkrm_id
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE data_cursor CURSOR 
		FOR
		    SELECT	smai.shkrm_id
		    FROM	@data_tab dt   
		    		INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
		    			ON	smai.shkrm_id = dt.shkrm_id
		    ORDER BY
		    	smai.stor_unit_residues_qty ASC
		;
		
		OPEN data_cursor;
		
		FETCH NEXT FROM data_cursor
		INTO @shkrm_id;
		
		WHILE @@FETCH_STATUS = 0
		      AND @qty_res > 0
		BEGIN
		    INSERT INTO Warehouse.SHKRawMaterialReserv
		    	(
		    		shkrm_id,
		    		spcvc_id,
		    		okei_id,
		    		quantity,
		    		dt,
		    		employee_id,
		    		rmid_id,
		    		rmodr_id
		    	)OUTPUT	INSERTED.shkrm_id,
		    	 		INSERTED.spcvc_id,
		    	 		INSERTED.okei_id,
		    	 		INSERTED.quantity,
		    	 		INSERTED.rmid_id,
		    	 		INSERTED.rmodr_id
		    	 INTO	@reserv_output (
		    	 		shkrm_id,
		    	 		spcvc_id,
		    	 		okei_id,
		    	 		quantity,
		    	 		rmid_id,
		    	 		rmodr_id
		    	 	)
		    SELECT	smai.shkrm_id,
		    		@spcvc_id,
		    		@okei_id,
		    		CASE 
		    		     WHEN smai.stor_unit_residues_qty - ISNULL(oar.qty, 0) >= @qty_res THEN @qty_res
		    		     ELSE smai.stor_unit_residues_qty - ISNULL(oar.qty, 0)
		    		END,
		    		@dt,
		    		@employee_id,
		    		NULL,
		    		NULL
		    FROM	Warehouse.SHKRawMaterialActualInfo smai   
		    		OUTER APPLY (
		    		      	SELECT	SUM(smr.quantity) qty
		    		      	FROM	Warehouse.SHKRawMaterialReserv smr
		    		      	WHERE	smr.shkrm_id = smai.shkrm_id
		    		      ) oar
		    WHERE	smai.shkrm_id = @shkrm_id
		    		AND	smai.stor_unit_residues_qty > ISNULL(oar.qty, 0)
		    		AND	@qty_res > 0
		    
		    FETCH NEXT FROM data_cursor
		    INTO @shkrm_id;
		    
		    SET @qty_res = @qty_need -(
		        	SELECT	ISNULL(SUM(ro.quantity), 0)
		        	FROM	@reserv_output ro
		        )
		END
		
		CLOSE data_cursor;
		DEALLOCATE data_cursor;
		
		IF @qty_res > 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Не хватило свободного остатка, обновите данные и попробуйте подобрать другой набор ШК', 16, 1)
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
				'I'
		FROM	@reserv_output sro
		
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