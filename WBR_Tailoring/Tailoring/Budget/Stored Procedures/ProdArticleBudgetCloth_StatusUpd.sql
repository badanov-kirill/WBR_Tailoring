CREATE PROCEDURE [Budget].[ProdArticleBudgetCloth_StatusUpd]
	@pabс_id INT,
	@status_id INT,
	@employee_id INT,
	@rv_bigint BIGINT,
	@comment VARCHAR(250) = NULL,
	@prev_count_meters SMALLINT = NULL,
	@ordered_count_meters SMALLINT = NULL,
	@actual_count_meters SMALLINT = NULL,
	@cloth_id INT = NULL,
	@color_id INT = NULL,
	@variant TINYINT = NULL,
	@is_main_color BIT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @pab_id INT
	
	DECLARE @status_approve INT = 2
	DECLARE @status_complaint INT = 6
	
	DECLARE @cloth_status_ordering INT = 1
	DECLARE @cloth_status_order_supplier INT = 2
	DECLARE @cloth_status_available INT = 3
	DECLARE @cloth_status_defect INT = 4
	DECLARE @cloth_status_passport INT = 5
	DECLARE @cloth_status_impossibil INT = 6
	DECLARE @cloth_status_complaint INT = 7
	DECLARE @cloth_status_cancel INT = 8
	
	DECLARE @budget_output TABLE (
	        	pab_id INT NOT NULL,
	        	pa_id INT NOT NULL,
	        	plan_count SMALLINT NOT NULL,
	        	plan_year SMALLINT NULL,
	        	plan_month TINYINT NULL,
	        	employee_id INT NOT NULL,
	        	dt [dbo].[SECONDSTIME] NOT NULL,
	        	planing_employee_id INT NOT NULL,
	        	planing_dt [dbo].[SECONDSTIME] NOT NULL,
	        	approved_employee INT NULL,
	        	approved_dt [dbo].[SECONDSTIME] NULL,
	        	bs_id INT NOT NULL,
	        	office_id INT NULL,
	        	comment VARCHAR(500) NULL
	        )
	
	DECLARE @budget_cloth_output TABLE (
	        	pabc_id INT NOT NULL,
	        	pab_id INT NOT NULL,
	        	cloth_id INT NOT NULL,
	        	color_id INT NOT NULL,
	        	prev_count_meters SMALLINT NOT NULL,
	        	ordered_count_meters SMALLINT NULL,
	        	actual_count_meters SMALLINT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	bcs_id INT NOT NULL,
	        	employee_id INT NOT NULL,
	        	comment VARCHAR(200) NULL,
	        	rv_bigint BIGINT,
	        	variant TINYINT NULL,
	        	is_main_color BIT NULL
	        )
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Budget.BudgetClothStatus bcs
	   	WHERE	bcs.bcs_id = @status_id
	   )
	BEGIN
	    RAISERROR('Статуса ткани с идентификтором %d не существует.', 16, 1, @status_id)
	    RETURN
	END
	
	IF @cloth_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Material.Cloth c
	       	WHERE	c.cloth_id = @cloth_id
	       )
	BEGIN
	    RAISERROR('Ткани с идентификтором %d не существует.', 16, 1, @cloth_id)
	    RETURN
	END
	
	IF @color_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Material.ClothColor cc
	       	WHERE	cc.color_id = @color_id
	       )
	BEGIN
	    RAISERROR('Цвета ткани с идентификтором %d не существует.', 16, 1, @color_id)
	    RETURN
	END
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN pabc.pabc_id IS NULL THEN 'Строки бюджета с номером ' + CAST(v.pabc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN @rv != pabc.rv THEN 'Эту строку бюджета уже отреадактировал сотудник с кодом ' + CAST(pabc.employee_id AS VARCHAR(10)) + ' ' 
	      	                        + CONVERT(VARCHAR(20), pabc.dt, 121) 
	      	                        +
	      	                        ', перечитайте данные и попробуйте снова'
	      	                   WHEN @status_id NOT IN (@cloth_status_ordering, @cloth_status_cancel) AND pab.bs_id NOT IN (@status_approve, @status_complaint) THEN 
	      	                        'Менять статус ткани можно только у изделий со статусом "Утверждено" или "Непредвиденная ситуация"'
	      	                   WHEN @status_id != @cloth_status_ordering AND ISNULL(@prev_count_meters, pabc.prev_count_meters) != pabc.prev_count_meters THEN 
	      	                        'Изменять количество заказываемых метров можно только с переводом в статус заказ от дизайнера'
	      	                   WHEN @status_id != @cloth_status_order_supplier AND ISNULL(@ordered_count_meters, pabc.ordered_count_meters) != pabc.ordered_count_meters THEN 
	      	                        'Изменять количество заказываемых метров у поставщика можно только с переводом в статус заказ у поставщика'
	      	                   WHEN @status_id = @cloth_status_order_supplier AND @ordered_count_meters IS NULL THEN 'Укажите количество заказываемых метров'
	      	                   WHEN @status_id NOT IN (@cloth_status_passport, @cloth_status_available, @cloth_status_complaint) AND @actual_count_meters IS NOT 
	      	                        NULL THEN 
	      	                        'Изменять фактическое количество метром можно только с переводом в статус поступления на склад, передачи паспартов или непредвиденной ситуации'
	      	                   WHEN @status_id = @cloth_status_passport AND @actual_count_meters IS NULL THEN 'Укажите фактическое количество метров'
	      	                   WHEN @status_id != @cloth_status_ordering AND @cloth_id IS NOT NULL THEN 
	      	                        'Изменять ткань можно только с переводом в статус заказ от дизайнера'
	      	                   WHEN @status_id != @cloth_status_ordering AND @color_id IS NOT NULL THEN 
	      	                        'Изменять цвет можно только с переводом в статус заказ от дизайнера'
	      	                   WHEN @status_id = @cloth_status_ordering AND pabc.bcs_id NOT IN (@cloth_status_ordering, @cloth_status_defect, @cloth_status_impossibil, @cloth_status_complaint) THEN 
	      	                        'Повторно заказать ткань можно только из статусов "Брак" ,"Невозможно исполнить" и "Непредвиденная ситуация", сейчас ткань в статусе "' 
	      	                        + bcs.bcs_name 
	      	                        + '"'
	      	                   WHEN @status_id = @cloth_status_order_supplier AND pabc.bcs_id NOT IN (@cloth_status_order_supplier, @cloth_status_ordering) THEN 
	      	                        'Заказать у поставщика можно из статуса "Заказ от дизайнера", сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   WHEN @status_id = @cloth_status_available AND pabc.bcs_id NOT IN (@cloth_status_available, @cloth_status_order_supplier) THEN 
	      	                        'Проставить статус "Поставка", можно только на заказанные у поставщика ткани, сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   WHEN @status_id = @cloth_status_defect AND pabc.bcs_id NOT IN (@cloth_status_defect, @cloth_status_available, @cloth_status_passport) THEN 
	      	                        'Отбраковать можно ткани поступившие на склад, сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   WHEN @status_id = @cloth_status_passport AND pabc.bcs_id NOT IN (@cloth_status_passport, @cloth_status_available, @cloth_status_defect) THEN 
	      	                        'Паспорт можно получить только на поступившие ткани, сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   WHEN @status_id = @cloth_status_impossibil AND pabc.bcs_id NOT IN (@cloth_status_impossibil, @cloth_status_ordering, @cloth_status_order_supplier, @cloth_status_defect) THEN 
	      	                        'Статус "Невозможно исполнить" можно проставить на не поступившие ткани, сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   WHEN @status_id = @cloth_status_cancel AND pabc.pabc_id NOT IN (@cloth_status_cancel, @cloth_status_ordering, @cloth_status_complaint) THEN 
	      	                        'Отказаться можно от ткани не в работе, сейчас ткань в статусе "' + bcs.bcs_name + '"'
	      	                   ELSE NULL
	      	              END,
			@pab_id = pabc.pab_id
	FROM	(VALUES(@pabс_id))v(pabc_id)   
			LEFT JOIN	Budget.ProdArticleBudgetCloth pabc   
			INNER JOIN	Budget.BudgetClothStatus bcs
				ON	bcs.bcs_id = pabc.bcs_id   
			INNER JOIN	Budget.ProdArticleBudget pab
				ON	pab.pab_id = pabc.pab_id
				ON	pabc.pabc_id = v.pabc_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	(SELECT	CASE 
	   	    	       	     WHEN pabc.pabc_id = @pabс_id THEN ISNULL(@color_id, pabc.color_id)
	   	    	       	     ELSE pabc.color_id
	   	    	       	END     color_id,
	   	    	 		CASE 
	   	    	 		     WHEN pabc.pabc_id = @pabс_id THEN ISNULL(@is_main_color, pabc.is_main_color)
	   	    	 		     ELSE pabc.is_main_color
	   	    	 		END     is_main_color
	   	    	 FROM	Budget.ProdArticleBudgetCloth pabc
	   	    	 WHERE	pabc.pab_id = @pab_id)d
	   	WHERE	d.is_main_color = 1
	   	GROUP BY
	   		d.color_id
	   	HAVING
	   		SUM(1) > 1
	   )
	BEGIN
	    RAISERROR('Неверно указаны основные цвета, они не должны повторяться', 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	(SELECT	CASE 
	   	    	       	     WHEN pabc.pabc_id = @pabс_id THEN ISNULL(@variant, pabc.variant)
	   	    	       	     ELSE pabc.variant
	   	    	       	END     variant,
	   	    	 		CASE 
	   	    	 		     WHEN pabc.pabc_id = @pabс_id THEN ISNULL(@is_main_color, pabc.is_main_color)
	   	    	 		     ELSE pabc.is_main_color
	   	    	 		END     is_main_color
	   	    	 FROM	Budget.ProdArticleBudgetCloth pabc
	   	    	 WHERE	pabc.pab_id = @pab_id)d
	   	GROUP BY
	   		d.variant
	   	HAVING
	   		SUM(CASE WHEN d.is_main_color = 1 THEN 1 ELSE 0 END) != 1
	   )
	BEGIN
	    RAISERROR('Неверно указаны основные цвета, на каждый вариант должен быть один основной цвет', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Budget.ProdArticleBudgetCloth
		SET 	cloth_id = ISNULL(@cloth_id, cloth_id),
				color_id = ISNULL(@color_id, color_id),
				prev_count_meters = ISNULL(@prev_count_meters, prev_count_meters),
				ordered_count_meters = ISNULL(@ordered_count_meters, ordered_count_meters),
				actual_count_meters = ISNULL(@actual_count_meters, actual_count_meters),
				dt = @dt,
				bcs_id = @status_id,
				employee_id = @employee_id,
				comment = ISNULL(@comment, comment),
				variant = ISNULL(@variant, variant),
				is_main_color = ISNULL(@is_main_color, is_main_color)
				OUTPUT	INSERTED.pabc_id,
						INSERTED.pab_id,
						INSERTED.cloth_id,
						INSERTED.color_id,
						INSERTED.prev_count_meters,
						INSERTED.ordered_count_meters,
						INSERTED.actual_count_meters,
						INSERTED.dt,
						INSERTED.bcs_id,
						INSERTED.employee_id,
						INSERTED.comment,
						CAST(INSERTED.rv AS BIGINT),
						INSERTED.variant,
						INSERTED.is_main_color
				INTO	@budget_cloth_output (
						pabc_id,
						pab_id,
						cloth_id,
						color_id,
						prev_count_meters,
						ordered_count_meters,
						actual_count_meters,
						dt,
						bcs_id,
						employee_id,
						comment,
						rv_bigint,
						variant,
						is_main_color
					)
		WHERE	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Ну удалось зафиксировать изменение статуса, попробуйте снова', 16, 1)
		    RETURN
		END
		
		INSERT INTO History.ProdArticleBudgetCloth
			(
				pabc_id,
				pab_id,
				cloth_id,
				color_id,
				prev_count_meters,
				ordered_count_meters,
				actual_count_meters,
				dt,
				bcs_id,
				employee_id,
				comment,
				variant,
				is_main_color
			)
		SELECT	bco.pabc_id,
				bco.pab_id,
				bco.cloth_id,
				bco.color_id,
				bco.prev_count_meters,
				bco.ordered_count_meters,
				bco.actual_count_meters,
				bco.dt,
				bco.bcs_id,
				bco.employee_id,
				bco.comment,
				bco.variant,
				bco.is_main_color
		FROM	@budget_cloth_output bco
		
		IF @status_id = @cloth_status_complaint
		   OR @status_id = @cloth_status_defect
		   OR @status_id = @cloth_status_impossibil
		BEGIN
		    UPDATE	Budget.ProdArticleBudget
		    SET 	employee_id     = @employee_id,
		    		dt              = @dt,
		    		bs_id           = @status_complaint
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
		END
		
		COMMIT TRANSACTION
		
		SELECT	bco.rv_bigint
		FROM	@budget_cloth_output bco
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