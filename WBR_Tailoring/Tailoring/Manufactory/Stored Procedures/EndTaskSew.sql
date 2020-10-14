CREATE PROCEDURE [Manufactory].[EndTaskSew]
	@ts_id INT,
	@has_problem BIT,
	@comment VARCHAR(500) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	DECLARE @proc_id INT
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	DECLARE @employee_id INT
	DECLARE @sketch_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Задания с номером ' + CAST(v.ts_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN ts.sew_end_work_dt IS NOT NULL THEN 'Задания с номером ' + CAST(v.ts_id AS VARCHAR(10)) 
	      	                        + ' уже выполнено'
	      	                   ELSE NULL
	      	              END,
	      	@employee_id = ts.sew_employee_id,
	      	@sketch_id = s.sketch_id
	FROM	(VALUES(@ts_id))v(ts_id)   
			LEFT JOIN	Manufactory.TaskSew ts
			INNER JOIN Manufactory.TaskSewSample tss
			INNER JOIN Manufactory.[Sample] s
				ON s.sample_id = tss.sample_id
				ON tss.ts_id = ts.ts_id
				ON	ts.ts_id = v.ts_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
	BEGIN TRANSACTION
	
		UPDATE	Manufactory.TaskSew
		SET 	sew_end_work_dt = @dt,
				comment = ISNULL(@comment, comment)
		WHERE	ts_id = @ts_id
		
		IF @has_problem = 1
		BEGIN
		    UPDATE	Manufactory.TaskSewSample
		    SET 	has_problem_dt     = @dt
		    WHERE	ts_id              = @ts_id
		    		AND	has_problem_dt IS NULL
		END
		
		UPDATE	Warehouse.MaterialInSketch
		SET 	return_qty = 0,
				return_stor_unit_residues_qty = 0,
				return_dt = @dt
				OUTPUT	INSERTED.shkrm_id
				INTO	@shkrm_tab (
						shkrm_id
					)
		WHERE sketch_id = @sketch_id
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

