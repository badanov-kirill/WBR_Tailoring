CREATE PROCEDURE [Budget].[ProdArticleBudgetCloth_Add]
	@pab_id INT,
	@employee_id INT,
	@cloth_id INT,
	@color_id INT,
	@count_meters SMALLINT,
	@comment VARCHAR(200) = NULL,
	@variant TINYINT,
	@is_main_color BIT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @status_planing INT = 1
	DECLARE @status_approve INT = 2
	DECLARE @status_to_correct INT = 4
	DECLARE @status_complaint INT = 6
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.Cloth c
	   	WHERE	c.cloth_id = @cloth_id
	   )
	BEGIN
	    RAISERROR('Ткани с кодом (%d) не существует', 16, 1, @cloth_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothColor сc
	   	WHERE	сc.color_id = @color_id
	   )
	BEGIN
	    RAISERROR('Цвета ткани с кодом (%d) не существует', 16, 1, @color_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN pab.pab_id IS NULL THEN 'Строки бюджета с номером ' + CAST(v.pab_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN pab.bs_id NOT IN (@status_planing, @status_approve, @status_to_correct, @status_complaint) THEN 'Этот артикул в статусе ' +
	      	                        bs.bs_name + ' . Добавлять ткань нельзя'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@pab_id))v(pab_id)   
			LEFT JOIN	Budget.ProdArticleBudget pab   
			INNER JOIN	Budget.BudgetStatus bs
				ON	bs.bs_id = pab.bs_id
				ON	pab.pab_id = v.pab_id
	WHERE	pab.pab_id IS NULL
			OR	pab.bs_id NOT IN (@status_planing, @status_approve, @status_to_correct, @status_complaint)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Budget.ProdArticleBudgetCloth pabc
	   	WHERE	pabc.cloth_id = @cloth_id
	   			AND	pabc.color_id = @color_id
	   			AND	pabc.pab_id = @pab_id
	   )
	BEGIN
	    RAISERROR('Такая ткань в этом цвете уже запланирована', 16, 1)
	    RETURN
	END
	
	IF @is_main_color = 1
	   AND EXISTS (
	       	SELECT	1
	       	FROM	Budget.ProdArticleBudgetCloth pabc
	       	WHERE	pabc.pab_id = @pab_id
	       			AND	pabc.color_id = @color_id
	       			AND	pabc.is_main_color = 1
	       )
	BEGIN
	    RAISERROR('Такой цвет уже выбран основным у этой модели', 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	(SELECT	pabc.variant,
	   	    	 		pabc.is_main_color
	   	    	 FROM	Budget.ProdArticleBudgetCloth pabc
	   	    	 WHERE	pabc.pab_id = @pab_id
	   	    	UNION ALL
	   	    	SELECT	@variant           variant,
	   	    			@is_main_color     is_main_color)d
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
		
		INSERT INTO Budget.ProdArticleBudgetCloth
			(
				pab_id,
				cloth_id,
				color_id,
				prev_count_meters,
				dt,
				employee_id,
				comment,
				bcs_id,
				variant,
				is_main_color
			)OUTPUT	INSERTED.pabc_id,
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
			 		INSERTED.variant,
			 		INSERTED.is_main_color
			 INTO	History.ProdArticleBudgetCloth (
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
		VALUES
			(
				@pab_id,
				@cloth_id,
				@color_id,
				@count_meters,
				@dt,
				@employee_id,
				@comment,
				@status_planing,
				@variant,
				@is_main_color
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