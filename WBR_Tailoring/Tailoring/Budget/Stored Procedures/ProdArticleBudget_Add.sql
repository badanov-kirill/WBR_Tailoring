CREATE PROCEDURE [Budget].[ProdArticleBudget_Add]
	@pa_id INT,
	@plan_count SMALLINT,
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@employee_id INT,
	@comment VARCHAR(500) = NULL,
	@data_xml XML
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @status_id INT = 1
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @data_tab TABLE (cloth_id INT, color_id INT, count_meters SMALLINT, comment VARCHAR(200), variant TINYINT NULL, is_main_color BIT NULL)
	DECLARE @error_message VARCHAR(MAX)
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
	        	variant TINYINT NULL,
	        	is_main_color BIT NULL
	        )
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticle pa
	   	WHERE	pa.pa_id = @pa_id
	   )
	BEGIN
	    RAISERROR('Артикула с идентификатором %d не существует', 16, 1, @pa_id)
	END
	
	IF @plan_month < 1
	   OR @plan_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @plan_month)
	    RETURN
	END
	
	IF @plan_year < (YEAR(@dt) - 1)
	   OR @plan_year > (YEAR(@dt) + 1)
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @plan_year)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			cloth_id,
			color_id,
			count_meters,
			comment,
			variant,
			is_main_color
		)
	SELECT	ml.value('@id', 'int'),
			ml.value('@clr', 'int'),
			ml.value('@metr', 'smallint'),
			ml.value('@comm', 'varchar(200)'),
			ml.value('@var', 'tinyint'),
			ml.value('@main', 'bit')
	FROM	@data_xml.nodes('root/detail')x(ml)
	
	SELECT	@error_message = 'Тканей с кодами '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.cloth_id AS VARCHAR(10))
	      			FROM	@data_tab d   
	      					LEFT JOIN	Material.Cloth c
	      						ON	c.cloth_id = d.cloth_id
	      			WHERE	c.cloth_id IS NULL
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' не существует'
	
	IF @error_message IS NOT NULL
	BEGIN
	    RAISERROR(@error_message, 16, 1)
	    RETURN
	END
	
	SELECT	@error_message = 'Цветов тканей с кодами '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.color_id AS VARCHAR(10))
	      			FROM	@data_tab d   
	      					LEFT JOIN	Material.ClothColor c
	      						ON	c.color_id = d.color_id
	      			WHERE	c.color_id IS NULL
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' не существует'
	
	IF @error_message IS NOT NULL
	BEGIN
	    RAISERROR(@error_message, 16, 1)
	    RETURN
	END
	
	SELECT	@error_message = 'Ткань в цвете '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + cl.cloth_name + ' - ' + c.color_name
	      			FROM	@data_tab d   
	      					INNER JOIN	Material.ClothColor c
	      						ON	c.color_id = d.color_id   
	      					INNER JOIN	Material.Cloth cl
	      						ON	cl.cloth_id = d.cloth_id
	      			GROUP BY
	      				cl.cloth_name,
	      				c.color_name
	      			HAVING
	      				SUM(1) > 1
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' повторяется больше одного раза.'
	
	IF @error_message IS NOT NULL
	BEGIN
	    RAISERROR(@error_message, 16, 1)
	    RETURN
	END
	
	SELECT	@error_message = 'Цвет '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.color_id AS VARCHAR(10))
	      			FROM	@data_tab d
	      			WHERE	d.is_main_color = 1
	      			GROUP BY
	      				d.color_id
	      			HAVING
	      				SUM(1) > 1
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' выбран как основной больше одного раза.'
	
	IF @error_message IS NOT NULL
	BEGIN
	    RAISERROR(@error_message, 16, 1)
	    RETURN
	END
	
	SELECT	@error_message = 'У вариантов '
	      	+
	      	STUFF(
	      		(
	      			SELECT	', ' + CAST(d.variant AS VARCHAR(10))
	      			FROM	@data_tab d
	      			WHERE	d.is_main_color = 1
	      			GROUP BY
	      				d.variant
	      			HAVING
	      				SUM(CASE WHEN d.is_main_color = 1 THEN 1 ELSE 0 END) != 1
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	)
	      	+
	      	' неверно указаны основные цвета.'
	
	IF @error_message IS NOT NULL
	BEGIN
	    RAISERROR(@error_message, 16, 1)
	    RETURN
	END
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	Budget.ProdArticleBudget pab
	   	WHERE	pab.pa_id = @pa_id
	   			AND	pab.plan_year = @plan_year
	   			AND	pab.plan_month = @plan_month
	   )
	BEGIN
	    RAISERROR('Этот артикул уже запланирован на этот месяц', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Budget.ProdArticleBudget
			(
				pa_id,
				plan_count,
				plan_year,
				plan_month,
				employee_id,
				dt,
				planing_employee_id,
				planing_dt,
				bs_id,
				comment
			)OUTPUT	INSERTED.pab_id,
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
			 INTO	@budget_output (
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
		VALUES
			(
				@pa_id,
				@plan_count,
				@plan_year,
				@plan_month,
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				@status_id,
				@comment
			)
		
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
			 		variant,
			 		is_main_color
			 	)
		SELECT	bo.pab_id,
				d.cloth_id,
				d.color_id,
				d.count_meters,
				@dt,
				@employee_id,
				d.comment,
				@status_id,
				d.variant,
				d.is_main_color
		FROM	@budget_output bo   
				CROSS JOIN	@data_tab d		
		
		INSERT INTO History.ProdArticleBudget
			(
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
		SELECT	bo.pab_id,
				bo.pa_id,
				bo.plan_count,
				bo.plan_year,
				bo.plan_month,
				bo.employee_id,
				bo.dt,
				bo.planing_employee_id,
				bo.planing_dt,
				bo.approved_employee,
				bo.approved_dt,
				bo.bs_id,
				bo.office_id,
				bo.comment
		FROM	@budget_output bo
		
		
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