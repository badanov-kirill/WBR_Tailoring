CREATE PROCEDURE [Manufactory].[Sample_Add]
	@sketch_id INT,
	@st_id TINYINT,
	@pattern_perimeter INT,
	@cut_perimeter INT,
	@ts_id INT = NULL,
	@ct_id INT,
	@employee_id INT,
	@comment VARCHAR(250) = NULL
AS
	SET NOCOUNT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором
	DECLARE @state_need_tect_desig_correction_from_constructor TINYINT = 11 --Тех. эскиз отправлен на доработку конструктором	
	DECLARE @state_tech_design_take_job_amend_from_constructor TINYINT = 12 --Тех. эскиз взят на исправление от конструктора	
	DECLARE @state_tech_desig_confirm_from_constructor TINYINT = 13 --Тех. эскиз доработан по требованию конструктора
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @st_stm TINYINT = 4
	DECLARE @st_wh TINYINT = 5
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Manufactory.SampleType st
	   	WHERE	st.st_id = @st_id
	   )
	BEGIN
	    RAISERROR('Некорректо указан тип макет/образец', 16, 1, @st_id)
	    RETURN
	END
	
	IF @ts_id IS NOT NULL AND
	 NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.TechSize ts
	   	WHERE	ts.ts_id = @ts_id
	   )
	BEGIN
	    RAISERROR('Размера с кодом %d не существует', 16, 1, @ts_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Типа ткани с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END	
	
	IF @st_id = @st_stm AND (@pattern_perimeter > 0 OR @cut_perimeter > 0)
	BEGIN
	    RAISERROR('Для стм периметры необходимо указывать равными 0.', 16, 1, @ct_id)
	    RETURN
	END	
	
	IF @st_id = @st_wh AND (@pattern_perimeter > 0 OR @cut_perimeter > 0)
	BEGIN
	    RAISERROR('Для складского образца периметры необходимо указывать равными 0.', 16, 1, @ct_id)
	    RETURN
	END	
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN @st_id != @st_wh AND s.ss_id NOT IN (@state_constructor_take_job_add, @state_need_tect_desig_correction_from_constructor, @state_tech_design_take_job_amend_from_constructor, 
	      	                                       @state_tech_desig_confirm_from_constructor, @state_constructor_take_job_add_rework) THEN 'Текущий статус ' + ss.ss_name +
	      	                        ' установленый сотрудником с кодом' + CAST(s.employee_id AS VARCHAR(10)) 
	      	                        + ' ' + CONVERT(VARCHAR(20), s.dt, 121) +
	      	                        ' не допускает добавление макета/образца'
	      	                   WHEN s.tech_design = 0 THEN 'Необходимо сначала прикрепить технический эскиз'
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз удален, нльзя добавлять макет/образц'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			LEFT JOIN	Products.SketchStatus ss
				ON	ss.ss_id = s.ss_id   	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Manufactory.[Sample]
		  (
		    sketch_id,
		    st_id,
		    pattern_perimeter,
		    cut_perimeter,
		    ts_id,
		    ct_id,
		    employee_id,
		    dt,
		    is_deleted,
		    comment
		  )
		  OUTPUT INSERTED.sample_id
		VALUES
		  (
		    @sketch_id,
		    @st_id,
		    @pattern_perimeter,
		    @cut_perimeter,
		    @ts_id,
		    @ct_id,
		    @employee_id,
		    @dt,
		    0,
		    @comment
		  )
		  
		  UPDATE	s
		  SET 	s.ct_id = @ct_id
		  FROM	Products.Sketch s
		  WHERE	s.sketch_id = @sketch_id
		  		AND	s.ct_id != @ct_id
		  		AND @st_id != @st_wh
		
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