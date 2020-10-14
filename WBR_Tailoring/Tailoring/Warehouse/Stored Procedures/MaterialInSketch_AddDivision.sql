CREATE PROCEDURE [Warehouse].[MaterialInSketch_AddDivision]
	@sketch_id INT,
	@task_sample_id INT,
	@src_shkrm_id INT,
	@dst_shkrm_id INT,
	@employee_id INT,
	@dst_qty DECIMAL(9, 3),
	@is_defected BIT = NULL,
	@defected_descr VARCHAR(900) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 19
	DECLARE @proc_id INT
	DECLARE @place_id INT
	DECLARE @okei_id INT
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @dst_stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @recive_employee_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID	
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.cut_end_of_work_dt IS NOT NULL AND oas.sew_employee_id IS NULL THEN 'Задание уже закрыто, выдавать материал нельзя'
	      	                   WHEN w.workshop_id IS NULL THEN 'Для офиса задания № ' + CAST(ts.office_id AS VARCHAR(10)) + ' не указан цех'
	      	                   WHEN oa.sketch_id IS NULL THEN 'В задании с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' нет эскиза № ' + CAST(@sketch_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
			@place_id = w.place_id,
			@recive_employee_id = ISNULL(ts.cut_employee_id, @employee_id)
	FROM	(VALUES(@task_sample_id))v(task_sample_id)   
			LEFT JOIN	Manufactory.TaskSample ts   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = ts.office_id   
			LEFT JOIN	Warehouse.Workshop w
				ON	w.workshop_id = os.design_workshop_id
				ON	ts.task_sample_id = v.task_sample_id   
			OUTER APPLY (
			      	SELECT	TOP(1) s.sketch_id
			      	FROM	Manufactory.[Sample] s
			      	WHERE	s.task_sample_id = ts.task_sample_id
			      			AND	s.sketch_id = @sketch_id
			      ) oa
			OUTER APPLY (
			      	SELECT TOP(1)	tsew.sew_employee_id
			      	FROM	Manufactory.TaskSewSample tss   
			      			INNER JOIN	Manufactory.TaskSew tsew
			      				ON	tsew.ts_id = tss.ts_id   
			      			INNER JOIN	Manufactory.[Sample] s
			      				ON	s.sample_id = tss.sample_id
			      	WHERE	s.task_sample_id = ts.task_sample_id
			      			AND	tsew.sew_employee_id IS NOT NULL
			      			AND	tsew.sew_end_work_dt IS NULL
			      ) oas
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN sms.state_id = @shkrm_state_dst THEN 'Штрихкод уже выдан'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN mipds.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным в документе №' + CAST(mipds.mip_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   WHEN cis2.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным в выдачу №' + CAST(cis2.covering_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   WHEN mis.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' числится выданным на проработку эскиза № ' +
	      	                        CAST(mis.sketch_id AS VARCHAR(10)) 
	      	                        + ', сначала верните его.'
	      	                   ELSE NULL
	      	              END,
			@okei_id                        = smai.okei_id,
			@stor_unit_residues_okei_id     = smai.stor_unit_residues_okei_id,
			@dst_stor_unit_residues_qty = smai.stor_unit_residues_qty * @dst_qty / smai.qty
	FROM	(VALUES(@src_shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = sm.shkrm_id   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai 			
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.MaterialInProductionDetailShk mipds
				ON	mipds.shkrm_id = v.shkrm_id
				AND	mipds.return_dt IS NULL   
			LEFT JOIN	Planing.CoveringIssueSHKRm cis2
				ON	cis2.shkrm_id = sm.shkrm_id
				AND	cis2.return_dt IS NULL   
			LEFT JOIN	Warehouse.MaterialInSketch mis
				ON	mis.shkrm_id = sm.shkrm_id
				AND	mis.return_dt IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC Warehouse.SHKRawMaterial_Division_v2
			@src_shkrm_id = @src_shkrm_id,
			@dst_shkrm_id = @dst_shkrm_id,
			@employee_id = @employee_id,
			@dst_qty = @dst_qty,
			@is_defected = @is_defected,
			@defected_descr = @defected_descr,
			@dst_reserv = NULL		
		
		UPDATE	s
		SET 	state_id = @shkrm_state_dst,
				dt = @dt,
				employee_id = @employee_id
				OUTPUT	INSERTED.shkrm_id,
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
		FROM	Warehouse.SHKRawMaterialState s
		WHERE	shkrm_id = @dst_shkrm_id		
		
		;
		MERGE Warehouse.SHKRawMaterialOnPlace t
		USING (
		      	SELECT	@dst_shkrm_id shkrm_id
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
		
		INSERT INTO Warehouse.MaterialInSketch
			(
				sketch_id,
				task_sample_id,
				shkrm_id,
				okei_id,
				qty,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				dt,
				employee_id,
				recive_employee_id
			)
		VALUES
			(
				@sketch_id,
				@task_sample_id,
				@dst_shkrm_id,
				@okei_id,
				@dst_qty,
				@stor_unit_residues_okei_id,
				@dst_stor_unit_residues_qty,
				@dt,
				@employee_id,
				@recive_employee_id
			)
		
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