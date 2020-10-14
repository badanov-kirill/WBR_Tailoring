CREATE PROCEDURE [Warehouse].[SHKRawMaterial_Division_v2]
	@src_shkrm_id INT,
	@dst_shkrm_id INT,
	@employee_id INT,
	@dst_qty DECIMAL(9, 3),
	@is_defected BIT = NULL,
	@defected_descr VARCHAR(900) = NULL,
	@dst_reserv XML
AS
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @proc_id INT
	DECLARE @place_id INT
	DECLARE @shkrm_state_dst INT = 10
	DECLARE @shkrm_state_dst2 INT
	DECLARE @dst_amount DECIMAL(19, 8)
	DECLARE @dst_stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @dst_gross_mass INT
	DECLARE @doc_id INT
	DECLARE @doc_type_id TINYINT
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @color_id INT
	DECLARE @su_id INT
	DECLARE @nds TINYINT
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @suppliercontract_id INT
	DECLARE @okei_id INT
	DECLARE @frame_width SMALLINT
	DECLARE @tissue_density SMALLINT
	DECLARE @dst_reserv_tab TABLE (spcvc_id INT)
	DECLARE @base_src_stor_unit_residues_qty DECIMAL(9, 3)
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Такого ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN sm.dt_mapping IS NOT NULL THEN 'Этот ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже был привязан к материалу '
	      	                   WHEN smai.shkrm_id IS NOT NULL THEN 'По этому ШК ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' числится ' + rmt.rmt_name + ' (' + a.art_name + ') ' + cc.color_name + CHAR(10) +
	      	                        'Кол-во ' + CAST(smai.qty AS VARCHAR(10)) + CHAR(10) +
	      	                        'Ед. изм. ' + o.symbol + CHAR(10) +
	      	                        'Сумма ' + CAST(sma.amount AS VARCHAR(19))
	      	                   WHEN sms.shkrm_id IS NOT NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' статус' + smsd.state_name + ', использовать данный шк для разделения запрещено'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@dst_shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = sm.shkrm_id
	
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан. Разделать нельзя.'
	      	                   WHEN smai.qty = 0 THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' без остатка, сначала необходимо инвентаризировать.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN smai.qty < @dst_qty THEN 'Остаток ' + CAST(smai.qty AS VARCHAR(10)) + ' меньше вычитаемого значения ' + CAST(@dst_qty AS VARCHAR(10))
	      	                   WHEN smai.qty = @dst_qty THEN 'Остаток  равен вычитаемому значению ' + CAST(@dst_qty AS VARCHAR(10))
	      	                   WHEN smai.is_defected = 0 AND @is_defected = 1 AND @defected_descr IS NULL THEN 'Не заполнено описание брака'
	      	                   WHEN smai.is_defected = 1 AND @is_defected IS NULL AND smdd.shkrm_id IS NULL AND @defected_descr IS NULL THEN 
	      	                        'Брак без описания, добавьте описание брака'
	      	                   WHEN @is_defected = 1 AND @defected_descr IS NULL AND smdd.shkrm_id IS NULL THEN 'Брак без описания, добавьте описание брака'
	      	                   WHEN smop.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не имеет места хранения. Разделать нельзя.'
	      	                   WHEN sma.final_dt IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не конечной стоимости. Разделать нельзя.'
	      	                   ELSE NULL
	      	              END,
			@dst_amount = (sma.amount * smai.stor_unit_residues_qty / sma.stor_unit_residues_qty) * @dst_qty / smai.qty,
			@dst_stor_unit_residues_qty = smai.stor_unit_residues_qty * @dst_qty / smai.qty,
			@dst_gross_mass = smai.gross_mass * @dst_qty / smai.qty,
			@doc_id = smai.doc_id,
			@doc_type_id = smai.doc_type_id,
			@suppliercontract_id = smai.suppliercontract_id,
			@rmt_id = smai.rmt_id,
			@art_id = smai.art_id,
			@color_id = smai.color_id,
			@su_id = smai.su_id,
			@nds = smai.nds,
			@stor_unit_residues_okei_id = smai.stor_unit_residues_okei_id,
			@is_defected = ISNULL(@is_defected, smai.is_defected),
			@defected_descr = ISNULL(@defected_descr, smdd.descr),
			@okei_id = smai.okei_id,
			@frame_width = smai.frame_width,
			@place_id = smop.place_id,
			@shkrm_state_dst2 = sms.state_id,
			@tissue_density = smi.tissue_density,
			@base_src_stor_unit_residues_qty = smai.stor_unit_residues_qty
	FROM	(VALUES(@src_shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sms.shkrm_id = v.shkrm_id   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
			LEFT JOIN	Warehouse.SHKRawMaterialDefectDescr smdd
				ON	smdd.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = smai.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop
				ON	smop.shkrm_id = v.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @dst_reserv_tab
		(
			spcvc_id
		)
	SELECT	ml.value('@spcvc[1]', 'int')
	FROM	@dst_reserv.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN drt.spcvc_id IS NOT NULL AND smr.spcvc_id IS NULL THEN 
	      	                        'Переданы неверные данные для переноса резервов по шк, для комплектации с кодом ' + CAST(drt.spcvc_id AS VARCHAR(10)) 
	      	                        + ' резерва на ШК ' + CAST(@src_shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN drt.spcvc_id IS NULL THEN 'Переданы неверные данные для переноса резервов по шк'
	      	                   ELSE NULL
	      	              END
	FROM	@dst_reserv_tab drt   
			LEFT JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = drt.spcvc_id
				AND	smr.shkrm_id = @src_shkrm_id
	WHERE	drt.spcvc_id IS NULL
			OR	smr.spcvc_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN (@base_src_stor_unit_residues_qty - @dst_stor_unit_residues_qty) < SUM(CASE WHEN drt.spcvc_id IS NULL THEN smr.quantity ELSE 0 END) THEN 
	      	                        'После деления, на базовом ШК, остается резервов ' + CAST(SUM(CASE WHEN drt.spcvc_id IS NULL THEN smr.quantity ELSE 0 END) AS VARCHAR(10)) 
	      	                        + ' больше, чем оставляемое в нем количество ' + CAST((@base_src_stor_unit_residues_qty - @dst_stor_unit_residues_qty) AS VARCHAR(10))
	      	                   WHEN @dst_stor_unit_residues_qty < SUM(CASE WHEN drt.spcvc_id IS NOT NULL THEN smr.quantity ELSE 0 END) THEN 
	      	                        'После деления, на новом ШК, остается резервов ' + CAST(SUM(CASE WHEN drt.spcvc_id IS NOT NULL THEN smr.quantity ELSE 0 END) AS VARCHAR(10)) 
	      	                        + ' больше, чем переносимое в него количество ' + CAST(@dst_stor_unit_residues_qty AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	Warehouse.SHKRawMaterialReserv smr   
			LEFT JOIN	@dst_reserv_tab drt
				ON	drt.spcvc_id = smr.spcvc_id
	WHERE	smr.shkrm_id = @src_shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION	
		
		UPDATE	Warehouse.SHKRawMaterial
		SET 	employee_id = @employee_id,
				dt = @dt,
				dt_mapping = @dt
		WHERE	shkrm_id = @dst_shkrm_id
				AND	dt_mapping IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 1
		    RAISERROR('Этот ШК %d уже был привязан к материалу ', 16, 1, @dst_shkrm_id)
		    RETURN
		END
		
		INSERT INTO Warehouse.SHKRawMaterialDivision
			(
				src_shkrm_id,
				dst_shkrm_id,
				stor_unit_residues_qty,
				stor_unit_residues_okei_id,
				dt,
				employee_id
			)
		VALUES
			(
				@src_shkrm_id,
				@dst_shkrm_id,
				@dst_stor_unit_residues_qty,
				@stor_unit_residues_okei_id,
				@dt,
				@employee_id
			)
		
		INSERT INTO Warehouse.SHKRawMaterialActualInfo
			(
				shkrm_id,
				doc_id,
				doc_type_id,
				suppliercontract_id,
				rmt_id,
				art_id,
				color_id,
				su_id,
				okei_id,
				qty,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				dt,
				employee_id,
				frame_width,
				is_defected,
				is_deleted,
				nds,
				gross_mass,
				tissue_density
			)OUTPUT	INSERTED.shkrm_id,
			 		INSERTED.doc_id,
			 		INSERTED.doc_type_id,
			 		INSERTED.suppliercontract_id,
			 		INSERTED.rmt_id,
			 		INSERTED.art_id,
			 		INSERTED.color_id,
			 		INSERTED.su_id,
			 		INSERTED.okei_id,
			 		INSERTED.qty,
			 		INSERTED.stor_unit_residues_okei_id,
			 		INSERTED.stor_unit_residues_qty,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		INSERTED.frame_width,
			 		INSERTED.is_defected,
			 		INSERTED.is_deleted,
			 		@proc_id,
			 		INSERTED.nds,
			 		INSERTED.gross_mass,
			 		INSERTED.is_terminal_residues,
			 		INSERTED.tissue_density
			 INTO	History.SHKRawMaterialActualInfo (
			 		shkrm_id,
			 		doc_id,
			 		doc_type_id,
			 		suppliercontract_id,
			 		rmt_id,
			 		art_id,
			 		color_id,
			 		su_id,
			 		okei_id,
			 		qty,
			 		stor_unit_residues_okei_id,
			 		stor_unit_residues_qty,
			 		dt,
			 		employee_id,
			 		frame_width,
			 		is_defected,
			 		is_deleted,
			 		proc_id,
			 		nds,
			 		gross_mass,
			 		is_terminal_residues,
			 		tissue_density
			 	)
		VALUES
			(
				@dst_shkrm_id,
				@doc_id,
				@doc_type_id,
				@suppliercontract_id,
				@rmt_id,
				@art_id,
				@color_id,
				@su_id,
				@okei_id,
				@dst_qty,
				@stor_unit_residues_okei_id,
				@dst_stor_unit_residues_qty,
				@dt,
				@employee_id,
				@frame_width,
				@is_defected,
				0,
				@nds,
				@dst_gross_mass,
				@tissue_density
			)
		
		INSERT INTO Warehouse.SHKRawMaterialInfo
			(
				shkrm_id,
				doc_id,
				doc_type_id,
				suppliercontract_id,
				rmt_id,
				art_id,
				color_id,
				su_id,
				frame_width,
				nds,
				tissue_density
			)OUTPUT	INSERTED.shkrm_id,
			 		INSERTED.doc_id,
			 		INSERTED.doc_type_id,
			 		INSERTED.suppliercontract_id,
			 		INSERTED.rmt_id,
			 		INSERTED.art_id,
			 		INSERTED.color_id,
			 		INSERTED.su_id,
			 		@dt,
			 		@employee_id,
			 		INSERTED.frame_width,
			 		@proc_id,
			 		INSERTED.nds,
			 		INSERTED.tissue_density
			 INTO	History.SHKRawMaterialInfo (
			 		shkrm_id,
			 		doc_id,
			 		doc_type_id,
			 		suppliercontract_id,
			 		rmt_id,
			 		art_id,
			 		color_id,
			 		su_id,
			 		dt,
			 		employee_id,
			 		frame_width,
			 		proc_id,
			 		nds,
			 		tissue_density
			 	)
		VALUES
			(
				@dst_shkrm_id,
				@doc_id,
				@doc_type_id,
				@suppliercontract_id,
				@rmt_id,
				@art_id,
				@color_id,
				@su_id,
				@frame_width,
				@nds,
				@tissue_density
			)
		
		INSERT INTO Warehouse.SHKRawMaterialAmount
			(
				shkrm_id,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				amount,
				gross_mass,
				final_dt
			)OUTPUT	INSERTED.shkrm_id,
			 		INSERTED.stor_unit_residues_okei_id,
			 		INSERTED.stor_unit_residues_qty,
			 		INSERTED.amount,
			 		INSERTED.gross_mass,
			 		@proc_id,
			 		@dt,
			 		@employee_id
			 INTO	History.SHKRawMaterialAmount (
			 		shkrm_id,
			 		stor_unit_residues_okei_id,
			 		stor_unit_residues_qty,
			 		amount,
			 		gross_mass,
			 		proc_id,
			 		dt,
			 		employee_id
			 	)
		VALUES
			(
				@dst_shkrm_id,
				@stor_unit_residues_okei_id,
				@dst_stor_unit_residues_qty,
				@dst_amount,
				@dst_gross_mass,
				@dt
			)
		
		UPDATE	Warehouse.SHKRawMaterialActualInfo
		SET 	qty = qty - @dst_qty,
				stor_unit_residues_qty = stor_unit_residues_qty - @dst_stor_unit_residues_qty,
				gross_mass = gross_mass - @dst_gross_mass,
				dt = @dt,
				employee_id = @employee_id,
				tissue_density = @tissue_density
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.doc_id,
						INSERTED.doc_type_id,
						INSERTED.suppliercontract_id,
						INSERTED.rmt_id,
						INSERTED.art_id,
						INSERTED.color_id,
						INSERTED.su_id,
						INSERTED.okei_id,
						INSERTED.qty,
						INSERTED.stor_unit_residues_okei_id,
						INSERTED.stor_unit_residues_qty,
						INSERTED.dt,
						INSERTED.employee_id,
						INSERTED.frame_width,
						INSERTED.is_defected,
						INSERTED.is_deleted,
						@proc_id,
						INSERTED.nds,
						INSERTED.gross_mass,
						INSERTED.is_terminal_residues,
						INSERTED.tissue_density
				INTO	History.SHKRawMaterialActualInfo (
						shkrm_id,
						doc_id,
						doc_type_id,
						suppliercontract_id,
						rmt_id,
						art_id,
						color_id,
						su_id,
						okei_id,
						qty,
						stor_unit_residues_okei_id,
						stor_unit_residues_qty,
						dt,
						employee_id,
						frame_width,
						is_defected,
						is_deleted,
						proc_id,
						nds,
						gross_mass,
						is_terminal_residues,
						tissue_density
					)
		WHERE	shkrm_id = @src_shkrm_id
		
		IF @is_defected = 1
		BEGIN
		    INSERT INTO Warehouse.SHKRawMaterialDefectDescr
		    	(
		    		shkrm_id,
		    		descr,
		    		dt,
		    		employee_id,
		    		okei_id,
		    		qty
		    	)OUTPUT	INSERTED.shkrm_id,
		    	 		INSERTED.descr,
		    	 		INSERTED.dt,
		    	 		INSERTED.employee_id,
		    	 		@proc_id
		    	 INTO	History.SHKRawMaterialDefectDescr (
		    	 		shkrm_id,
		    	 		descr,
		    	 		dt,
		    	 		employee_id,
		    	 		proc_id
		    	 	)
		    VALUES
		    	(
		    		@dst_shkrm_id,
		    		@defected_descr,
		    		@dt,
		    		@employee_id,
		    		@okei_id,
		    		@dst_qty
		    	)
		END
		
		INSERT INTO History.SHKRawMaterialState
			(
				shkrm_id,
				state_id,
				dt,
				employee_id,
				proc_id
			)
		VALUES
			(
				@src_shkrm_id,
				@shkrm_state_dst,
				@dt,
				@employee_id,
				@proc_id
			)
		
		INSERT INTO History.SHKRawMaterialState
			(
				shkrm_id,
				state_id,
				dt,
				employee_id,
				proc_id
			)
		VALUES
			(
				@src_shkrm_id,
				@shkrm_state_dst2,
				@dt,
				@employee_id,
				@proc_id
			)
		
		INSERT INTO History.SHKRawMaterialState
			(
				shkrm_id,
				state_id,
				dt,
				employee_id,
				proc_id
			)
		VALUES
			(
				@dst_shkrm_id,
				@shkrm_state_dst,
				@dt,
				@employee_id,
				@proc_id
			)
		
		INSERT INTO Warehouse.SHKRawMaterialState
			(
				shkrm_id,
				state_id,
				dt,
				employee_id
			)OUTPUT	INSERTED.shkrm_id,
			 		INSERTED.state_id,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		@proc_id
			 INTO	History.SHKRawMaterialState (
			 		shkrm_id,
			 		state_id,
			 		dt,
			 		employee_id,
			 		proc_id
			 	)
		VALUES
			(
				@dst_shkrm_id,
				@shkrm_state_dst2,
				@dt,
				@employee_id
			)
		
		MERGE Warehouse.SHKRawMaterialOnPlace t
		USING (
		      	SELECT	@src_shkrm_id shkrm_id
		      	UNION 
		      	SELECT	@dst_shkrm_id
		      ) s
				ON t.shkrm_id = s.shkrm_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.place_id = @place_id,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		shkrm_id,
		     		place_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.shkrm_id,
		     		@place_id,
		     		@dt,
		     		@employee_id
		     	)
		     OUTPUT	INSERTED.shkrm_id,
		     		INSERTED.place_id,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		@proc_id
		     INTO	History.SHKRawMaterialOnPlace (
		     		shkrm_id,
		     		place_id,
		     		dt,
		     		employee_id,
		     		proc_id
		     	);
		     	
		UPDATE	smr
		SET 	shkrm_id = @dst_shkrm_id
		    	OUTPUT	INSERTED.shkrm_id,
		    			INSERTED.spcvc_id,
		    			INSERTED.okei_id,
		    			INSERTED.quantity,
		    			@dt,
		    			@employee_id,
		    			INSERTED.rmid_id,
		    			INSERTED.rmodr_id,
		    			@proc_id,
		    			'V'
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
				INNER JOIN	@dst_reserv_tab drt
					ON	drt.spcvc_id = smr.spcvc_id
		WHERE	smr.shkrm_id = @src_shkrm_id
		
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