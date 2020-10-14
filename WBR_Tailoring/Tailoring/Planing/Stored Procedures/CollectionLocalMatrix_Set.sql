CREATE PROCEDURE [Planing].[CollectionLocalMatrix_Set]
	@season_model_year SMALLINT,
	@season_local_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (subject_id INT, brand_id INT, plan_qty SMALLINT)
	DECLARE @error_text VARCHAR(MAX)
	
	IF @season_model_year < (YEAR(@dt) - 3)
	   OR @season_model_year > (YEAR(@dt) + 3)
	   OR @season_model_year IS NULL
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @season_model_year)
	    RETURN
	END		
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.SeasonLocal sl
	   	WHERE	sl.season_local_id = @season_local_id
	   )
	BEGIN
	    RAISERROR('Сезона коллекции с кодом (%d) не существует', 16, 1, @season_local_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			subject_id,
			brand_id,
			plan_qty
		)
	SELECT	ml.value('@subject[1]', 'int'),
			ml.value('@brand[1]', 'int'),
			ml.value('@qty[1]', 'smallint')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.subject_id IS NULL OR dt.brand_id IS NULL OR dt.plan_qty IS NULL THEN 'Некорректный XML'
	      	                   WHEN dt.subject_id IS NOT NULL AND dt.brand_id IS NOT NULL AND dt.plan_qty IS NOT NULL AND s.subject_id IS NULL THEN 
	      	                        'Предмета с кодом ' + CAST(dt.subject_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN dt.subject_id IS NOT NULL AND dt.brand_id IS NOT NULL AND dt.plan_qty IS NOT NULL AND b.brand_id IS NULL THEN 
	      	                        'Бренда с кодом ' + CAST(dt.brand_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Products.[Subject] s
				ON	s.subject_id = dt.subject_id   
			LEFT JOIN	Products.Brand b
				ON	b.brand_id = dt.brand_id
	WHERE	dt.subject_id IS NULL
			OR	dt.brand_id IS NULL
			OR	dt.plan_qty IS NULL
			OR	s.subject_id IS NULL
			OR	b.brand_id IS NULL 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		
		;
		WITH cte_Target AS (
			SELECT	clm.season_model_year,
					clm.season_local_id,
					clm.brand_id,
					clm.subject_id,
					clm.plan_qty,
					clm.employee_id,
					clm.dt
			FROM	Planing.CollectionLocalMatrix clm
			WHERE	clm.season_model_year = @season_model_year
					AND	clm.season_local_id = @season_local_id
		)
		MERGE cte_Target AS t
		USING @data_tab s
				ON s.subject_id = t.subject_id
				AND s.brand_id = t.brand_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.plan_qty = s.plan_qty,
		     		t.employee_id = @employee_id,
		     		t.dt = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		season_model_year,
		     		season_local_id,
		     		brand_id,
		     		subject_id,
		     		plan_qty,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		@season_model_year,
		     		@season_local_id,
		     		s.brand_id,
		     		s.subject_id,
		     		s.plan_qty,
		     		@employee_id,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
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