CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompleting_Actualize]
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX) 
	DECLARE @proc_id INT
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp_ready TINYINT = 4 --Подготовлены паспорта материалов
	DECLARE @cv_status_corr_reserv TINYINT = 5 --На изменение резервов
	DECLARE @cv_status_pasp_get TINYINT = 6 --Паспорта получены
	DECLARE @cv_status_to_layout TINYINT = 7 --Отправлен на раскладку
	DECLARE @cv_status_layout_close TINYINT = 8 --Раскладка привязана
	DECLARE @cv_status_add_as_compain TINYINT = 11 --Создан как компаньен
	
	DECLARE @cvc_state_covered_wh TINYINT = 3
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp_ready, @cv_status_corr_reserv, @cv_status_pasp_get, @cv_status_to_layout, 
	      	                                           @cv_status_layout_close, @cv_status_add_as_compain) THEN 'У текущей позиции ' + cvs.cvs_name +
	      	                        ', операция запрещена.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		INSERT INTO Planing.SketchPlanColorVariantCompleting
			(
				spcv_id,
				completing_id,
				completing_number,
				rmt_id,
				color_id,
				frame_width,
				okei_id,
				consumption,
				comment,
				dt,
				employee_id,
				cs_id
			)OUTPUT	INSERTED.spcvc_id,
			 		INSERTED.spcv_id,
			 		INSERTED.completing_id,
			 		INSERTED.completing_number,
			 		INSERTED.rmt_id,
			 		INSERTED.color_id,
			 		INSERTED.frame_width,
			 		INSERTED.okei_id,
			 		INSERTED.consumption,
			 		INSERTED.comment,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		INSERTED.cs_id,
			 		@proc_id
			 INTO	History.SketchPlanColorVariantCompleting (
			 		spcvc_id,
			 		spcv_id,
			 		completing_id,
			 		completing_number,
			 		rmt_id,
			 		color_id,
			 		frame_width,
			 		okei_id,
			 		consumption,
			 		comment,
			 		dt,
			 		employee_id,
			 		cs_id,
			 		proc_id
			 	)
		SELECT	spcv.spcv_id,
				sc.completing_id,
				sc.completing_number,
				sc.base_rmt_id,
				0,
				sc.frame_width,
				sc.okei_id,
				sc.consumption,
				sc.comment,
				@dt,
				sc.employee_id,
				@cvc_state_covered_wh
		FROM	Planing.SketchPlanColorVariant spcv   
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id   
				INNER JOIN	Products.SketchCompleting sc
					ON	sc.sketch_id = sp.sketch_id   
				LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcv_id = spcv.spcv_id
					AND	spcvc.completing_id = sc.completing_id
					AND	spcvc.completing_number = sc.completing_number
		WHERE	spcv.spcv_id = @spcv_id
				AND	spcvc.spcvc_id IS NULL
				AND	sc.is_deleted = 0
		
		
		UPDATE	spcvc
		SET 	consumption = CASE 
		    	                   WHEN sc.sc_id IS NOT NULL THEN sc.consumption
		    	                   WHEN sc.sc_id IS NULL AND spcvc.completing_id = 32 AND spcvc.completing_number = 1 AND NOT EXISTS (
		    	                        	SELECT	1
		    	                        	FROM	Warehouse.SHKRawMaterialReserv smr
		    	                        	WHERE	smr.spcvc_id = spcvc.spcvc_id
		    	                        ) THEN 0.001
		    	                   ELSE 0
		    	              END,
				rmt_id = CASE 
				              WHEN spcvc.completing_id = 32 AND spcvc.completing_number = 1 AND NOT EXISTS (
				                   	SELECT	1
				                   	FROM	Warehouse.SHKRawMaterialReserv smr
				                   	WHERE	smr.spcvc_id = spcvc.spcvc_id
				                   ) THEN 54
				              ELSE spcvc.rmt_id
				         END,
				okei_id = CASE 
				               WHEN NOT EXISTS (
				                    	SELECT	1
				                    	FROM	Warehouse.SHKRawMaterialReserv smr
				                    	WHERE	smr.spcvc_id = spcvc.spcvc_id
				                    ) AND sc.okei_id IS NOT NULL THEN sc.okei_id
				               WHEN NOT EXISTS (
				                    	SELECT	1
				                    	FROM	Warehouse.SHKRawMaterialReserv smr
				                    	WHERE	smr.spcvc_id = spcvc.spcvc_id
				                    ) AND sc.okei_id IS NULL AND spcvc.completing_id = 32 AND spcvc.completing_number = 1 THEN 616
				               ELSE spcvc.okei_id
				          END 
				OUTPUT	INSERTED.spcvc_id,
						INSERTED.spcv_id,
						INSERTED.completing_id,
						INSERTED.completing_number,
						INSERTED.rmt_id,
						INSERTED.color_id,
						INSERTED.frame_width,
						INSERTED.okei_id,
						INSERTED.consumption,
						INSERTED.comment,
						@dt,
						@employee_id,
						INSERTED.cs_id,
						@proc_id
				INTO	History.SketchPlanColorVariantCompleting (
						spcvc_id,
						spcv_id,
						completing_id,
						completing_number,
						rmt_id,
						color_id,
						frame_width,
						okei_id,
						consumption,
						comment,
						dt,
						employee_id,
						cs_id,
						proc_id
					)
		FROM	Planing.SketchPlanColorVariant spcv
				INNER JOIN	Planing.SketchPlan sp
					ON	sp.sp_id = spcv.sp_id
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcv_id = spcv.spcv_id
				LEFT JOIN	Products.SketchCompleting sc
					ON	sc.sketch_id = sp.sketch_id
					AND	spcvc.completing_id = sc.completing_id
					AND	spcvc.completing_number = sc.completing_number
					AND	sc.is_deleted = 0
		WHERE	spcv.spcv_id = @spcv_id
		
		INSERT INTO Planing.SketchPlanColorVariantCompleting
			(
				spcv_id,
				completing_id,
				completing_number,
				rmt_id,
				color_id,
				frame_width,
				okei_id,
				consumption,
				comment,
				dt,
				employee_id,
				cs_id
			)OUTPUT	INSERTED.spcvc_id,
			 		INSERTED.spcv_id,
			 		INSERTED.completing_id,
			 		INSERTED.completing_number,
			 		INSERTED.rmt_id,
			 		INSERTED.color_id,
			 		INSERTED.frame_width,
			 		INSERTED.okei_id,
			 		INSERTED.consumption,
			 		INSERTED.comment,
			 		INSERTED.dt,
			 		INSERTED.employee_id,
			 		INSERTED.cs_id,
			 		@proc_id
			 INTO	History.SketchPlanColorVariantCompleting (
			 		spcvc_id,
			 		spcv_id,
			 		completing_id,
			 		completing_number,
			 		rmt_id,
			 		color_id,
			 		frame_width,
			 		okei_id,
			 		consumption,
			 		comment,
			 		dt,
			 		employee_id,
			 		cs_id,
			 		proc_id
			 	)
		SELECT	@spcv_id,
				32,
				1,
				54,
				0,
				NULL,
				616,
				0.001,
				NULL,
				@dt,
				@employee_id,
				@cvc_state_covered_wh
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlanColorVariantCompleting spcvc
		     		WHERE	spcvc.spcv_id = @spcv_id
		     				AND	spcvc.completing_id = 32
		     				AND	spcvc.completing_number = 1
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