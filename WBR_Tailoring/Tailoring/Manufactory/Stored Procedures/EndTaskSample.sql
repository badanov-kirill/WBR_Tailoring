CREATE PROCEDURE [Manufactory].[EndTaskSample]
	@task_sample_id INT,
	@comment VARCHAR(250) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @employee_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.task_sample_id IS NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_end_of_work_dt IS NOT NULL THEN 'Задания с номером ' + CAST(v.task_sample_id AS VARCHAR(10)) 
	      	                        + ' уже выполнено'
	      	                   ELSE NULL
	      	              END,
			@employee_id = CASE 
			                    WHEN ts.pattern_end_of_work_dt IS NULL THEN ts.pattern_employee_id
			                    WHEN ts.cut_employee_id IS NOT NULL THEN ts.cut_employee_id
			                    ELSE ts.employee_id
			               END
	FROM	(VALUES(@task_sample_id))v(task_sample_id)   
			LEFT JOIN	Manufactory.TaskSample ts
				ON	ts.task_sample_id = v.task_sample_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Manufactory.TaskSample
		SET 	cut_end_of_work_dt = CASE 
		    	                          WHEN pattern_end_of_work_dt IS NOT NULL AND cut_end_of_work_dt IS NULL THEN @dt
		    	                          ELSE cut_end_of_work_dt
		    	                     END,
				cut_comment = CASE 
				                   WHEN pattern_end_of_work_dt IS NOT NULL AND cut_end_of_work_dt IS NULL THEN @comment
				                   ELSE cut_comment
				              END,
				pattern_end_of_work_dt = CASE 
				                              WHEN pattern_end_of_work_dt IS NULL THEN @dt
				                              ELSE pattern_end_of_work_dt
				                         END,
				pattern_comment = CASE 
				                       WHEN pattern_end_of_work_dt IS NULL THEN @comment
				                       ELSE pattern_comment
				                  END
		WHERE	task_sample_id = @task_sample_id
		
		UPDATE	Warehouse.MaterialInSketch
		SET 	return_qty = 0,
				return_stor_unit_residues_qty = 0,
				return_dt = @dt
				OUTPUT	INSERTED.shkrm_id
				INTO	@shkrm_tab (
						shkrm_id
					)
		WHERE	task_sample_id = @task_sample_id
				AND	return_dt IS NULL
		
		DELETE	sr		    
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
		FROM	Warehouse.SHKRawMaterialReserv sr
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = sr.shkrm_id
		     	)
		
		DELETE	smai		    
		      	OUTPUT	DELETED.shkrm_id,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialActualInfo (
		      			shkrm_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialActualInfo smai
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = smai.shkrm_id
		     	)
		
		DELETE	smdd		    
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialDefectDescr (
		      			shkrm_id,
		      			descr,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialDefectDescr smdd
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = smdd.shkrm_id
		     	)
		
		
		DELETE	ss	    
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialState (
		      			shkrm_id,
		      			state_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialState ss
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = ss.shkrm_id
		     	)
		
		DELETE	sop
		      	
		      	OUTPUT	DELETED.shkrm_id,
		      			NULL,
		      			@dt,
		      			@employee_id,
		      			@proc_id
		      	INTO	History.SHKRawMaterialOnPlace (
		      			shkrm_id,
		      			place_id,
		      			dt,
		      			employee_id,
		      			proc_id
		      		)
		FROM	Warehouse.SHKRawMaterialOnPlace sop
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@shkrm_tab st
		     		WHERE	st.shkrm_id = sop.shkrm_id
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
GO

