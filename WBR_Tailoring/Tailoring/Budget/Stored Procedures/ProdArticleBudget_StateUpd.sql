CREATE PROCEDURE [Budget].[ProdArticleBudget_StateUpd]
	@pab_id INT,
	@status_id INT,
	@employee_id INT,
	@office_id INT = NULL,
	@rv_bigint BIGINT,
	@comment VARCHAR(500) = NULL,
	@plan_count SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @status_planing INT = 1
	DECLARE @status_approve INT = 2
	DECLARE @status_cancel INT = 3
	DECLARE @status_to_correct INT = 4
	DECLARE @status_material_purchase INT = 5
	DECLARE @status_complaint INT = 6
	
	DECLARE @cloth_status_available INT = 3
	DECLARE @cloth_status_passport INT = 5
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Budget.BudgetStatus bs
	   	WHERE	bs.bs_id = @status_id
	   )
	BEGIN
	    RAISERROR('Статуса с кодом %d не существует.', 16, 1, @status_id)
	    RETURN
	END
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pab.pab_id IS NULL THEN 'Строки бюджета с номером ' + CAST(v.pab_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN @rv != pab.rv THEN 'Этоу строку бюджета уже отреадактировал сотрудник с кодом ' + CAST(pab.employee_id AS VARCHAR(10)) + ' ' 
	      	                        + CONVERT(VARCHAR(20), pab.dt, 121) +
	      	                        ', перечитайте данные и попробуйте снова'
	      	                   WHEN @status_id = @status_planing AND pab.bs_id NOT IN (@status_cancel, @status_to_correct, @status_complaint) THEN 
	      	                        'Повторно планировать можно только отклоненные, проблемные, либо отправленные на корретировку'
	      	                   WHEN @status_id = @status_approve AND pab.bs_id = @status_material_purchase THEN 
	      	                        'На этот артикул уже поступила ткань, повторно утверждать нельзя'
	      	                   WHEN @status_id = @status_approve AND pab.bs_id NOT IN (@status_approve, @status_planing, @status_cancel, @status_to_correct, @status_complaint) THEN 
	      	                        'Этот артикул в статусе ' + bs.bs_name + ' . Утверждать нельзя'
	      	                   WHEN @status_id = @status_cancel AND pab.bs_id NOT IN (@status_cancel, @status_planing, @status_approve, @status_to_correct, @status_complaint) THEN 
	      	                        'Этот артикул в статусе ' + bs.bs_name + ' . Отклонять нельзя'
	      	                   WHEN @status_id = @status_to_correct AND pab.bs_id NOT IN (@status_to_correct, @status_planing, @status_approve, @status_cancel, @status_complaint) THEN 
	      	                        'Этот артикул в статусе ' + bs.bs_name + ' . Отправлять на корректировку нельзя'
	      	                   WHEN @status_id = @status_material_purchase AND pab.bs_id NOT IN (@status_material_purchase, @status_approve, @status_complaint) THEN 
	      	                        'Этот артикул в статусе ' + bs.bs_name +
	      	                        ' . Переводить в статус "Материалы закуплены" можно только утвержденные артикулы '
	      	                   WHEN @status_id IN (@status_cancel, @status_to_correct) AND oa_cloth.cloth_purchase IS NOT NULL THEN 
	      	                        'Нельзя отклонить, ткань уже поступила на склад'
	      	                   WHEN @status_id IN (@status_approve, @status_material_purchase) AND @office_id IS NULL THEN 'Укажите офис'
	      	                   WHEN @status_id = @status_to_correct AND @comment IS NULL THEN 'При отклонении на корретировку необходимо указать комментарий'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@pab_id))v(pab_id)   
			LEFT JOIN	Budget.ProdArticleBudget pab   
			INNER JOIN	Budget.BudgetStatus bs
				ON	bs.bs_id = pab.bs_id
				ON	pab.pab_id = v.pab_id   
			OUTER APPLY (
			      	SELECT	1 cloth_purchase
			      	FROM	Budget.ProdArticleBudgetCloth pabc
			      	WHERE	pabc.pab_id = pab.pab_id
			      			AND	pabc.bcs_id IN (@cloth_status_available, @cloth_status_passport)
			      ) oa_cloth
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Budget.ProdArticleBudget
		SET 	employee_id = @employee_id,
				dt = @dt,
				approved_employee = CASE 
				                         WHEN @status_id = @status_approve THEN @employee_id
				                         ELSE approved_employee
				                    END,
				approved_dt = CASE 
				                   WHEN @status_id = @status_approve THEN @dt
				                   ELSE dt
				              END,
				bs_id = @status_id,
				office_id = @office_id,
				comment = ISNULL(@comment, comment),
				plan_count = ISNULL(@plan_count, plan_count)
				OUTPUT	INSERTED.pab_id,
						INSERTED.pa_id,
						INSERTED.plan_count,
						INSERTED.plan_year,
						INSERTED.plan_month,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.planing_employee_id,
						INSERTED.planing_dt,
						INSERTED.approved_employee,
						INSERTED.approved_dt,
						INSERTED.bs_id,
						INSERTED.office_id,
						INSERTED.comment
				INTO	History.ProdArticleBudget (
						pab_id,
						pa_id,
						plan_count,
						plan_year,
						plan_month,
						employee_id,
						dt,
						planing_employee_id,
						planing_dt,
						approved_employee,
						approved_dt,
						bs_id,
						office_id,
						comment
					)
		WHERE	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Ну удалось зафиксировать изменение статуса, попробуйте снова', 16, 1)
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 