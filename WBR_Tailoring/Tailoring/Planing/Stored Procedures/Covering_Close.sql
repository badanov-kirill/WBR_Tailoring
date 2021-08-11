CREATE PROCEDURE [Planing].[Covering_Close]
	@covering_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	DECLARE @cv_status_cutting TINYINT = 15 --Раскроен
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' уже закрыта.'
	      	                   --WHEN oa.shkrm_id IS NULL THEN 'По этой выдаче не выдан ни один материал. Отправлять на себистоимость нельзя'
	      	                   WHEN oa.shkrm_id IS NOT NULL AND oa.return_dt IS NULL THEN 
	      	                        'В выдаче есть шк, которые не вернули на склад. Отправлять на себестоимость нельзя'
	      	                   WHEN oaac.actual_count = 0 THEN 'По этой выдаче не внесено количество кроя. Отправлять на себистоимость нельзя'
	      	                   WHEN oa_master.no_master IS NOT NULL THEN 'В выдаче есть цветоварианты, которые мастер не взял в работу. Отправлять на себестоимость нельзя'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id   
			OUTER APPLY (
			      	SELECT	TOP(1) cis.shkrm_id,
			      			cis.return_dt
			      	FROM	Planing.CoveringIssueSHKRm cis
			      	WHERE	cis.covering_id = @covering_id
			      	ORDER BY
			      		CASE 
			      		     WHEN cis.return_dt IS NULL THEN 0
			      		     ELSE 1
			      		END
			      )oa
			OUTER APPLY (
			SELECT	SUM(ca.actual_count) actual_count
			FROM	Manufactory.Cutting cut   
					INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
						ON	spcvt.spcvts_id = cut.spcvts_id   
					INNER JOIN	Planing.SketchPlanColorVariant spcv
						ON	spcv.spcv_id = spcvt.spcv_id   
					INNER JOIN	Planing.CoveringDetail cd
						ON	cd.spcv_id = spcv.spcv_id   
					INNER JOIN	Manufactory.CuttingActual ca
						ON	ca.cutting_id = cut.cutting_id
			WHERE	cd.covering_id = c.covering_id	
			) oaac
			OUTER APPLY (
			SELECT	TOP(1) 1 no_master
			FROM	Planing.SketchPlanColorVariant spcv  
					INNER JOIN	Planing.CoveringDetail cd
						ON	cd.spcv_id = spcv.spcv_id   
			WHERE	cd.covering_id = c.covering_id	AND spcv.master_employee_id IS NULL
			) oa_master
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_rm_issue, @cv_status_cutting) THEN 'Есть цветовариает(ы) в статусе ' + cvs.cvs_name + ' переход запрещен.'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
	WHERE	cd.covering_id = @covering_id
			AND	spcv.cvs_id NOT IN (@cv_status_rm_issue) 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Planing.CoveringDetail cd   
	   			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	   				ON	spcvt.spcv_id = cd.spcv_id   
	   			INNER JOIN	Manufactory.Cutting c
	   				ON	c.spcvts_id = spcvt.spcvts_id   
	   			INNER JOIN	Manufactory.ProductUnicCode puc
	   				ON	puc.cutting_id = c.cutting_id
	   	WHERE	cd.covering_id = @covering_id
	   			AND	puc.operation_id = 11
	   )
	BEGIN
	    RAISERROR('Отправлять на себестоимость нельзя, есть не подтвержденное списание кроя', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	spcv
		SET 	employee_id = @employee_id,
				dt = @dt,
				cvs_id = @cv_status_cutting
				OUTPUT	INSERTED.spcv_id,
						INSERTED.sp_id,
						INSERTED.spcv_name,
						INSERTED.cvs_id,
						INSERTED.qty,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.is_deleted,
						INSERTED.comment,
						INSERTED.pan_id,
						INSERTED.corrected_qty,
						INSERTED.begin_plan_delivery_dt,
						INSERTED.end_plan_delivery_dt,
						INSERTED.sew_office_id,
						INSERTED.sew_deadline_dt,
						INSERTED.cost_plan_year,
						INSERTED.cost_plan_month,
						@proc_id
				INTO	History.SketchPlanColorVariant (
						spcv_id,
						sp_id,
						spcv_name,
						cvs_id,
						qty,
						employee_id,
						dt,
						is_deleted,
						comment,
						pan_id,
						corrected_qty,
						begin_plan_delivery_dt,
						end_plan_delivery_dt,
						sew_office_id,
						sew_deadline_dt,
						cost_plan_year,
						cost_plan_month,
						proc_id
					)
		FROM	Planing.SketchPlanColorVariant spcv
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcv.spcv_id
		WHERE	cd.covering_id = @covering_id
		
		UPDATE	c
		SET 	c.close_dt = @dt,
				c.close_employee_id = @employee_id
		FROM	Planing.Covering c
		WHERE	c.covering_id = @covering_id
				AND	c.close_dt IS NULL
				
		DELETE	r		    
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
		FROM	Warehouse.SHKRawMaterialReserv r   
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = r.spcvc_id   
				INNER JOIN	Planing.CoveringDetail cd
					ON	cd.spcv_id = spcvc.spcv_id
		WHERE	cd.covering_id = @covering_id
		
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
	