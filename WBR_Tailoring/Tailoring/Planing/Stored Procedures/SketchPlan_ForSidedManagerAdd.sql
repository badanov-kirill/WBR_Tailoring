CREATE PROCEDURE [Planing].[SketchPlan_ForSidedManagerAdd]
	@sketch_id INT,
	@employee_id INT,
	@comment VARCHAR(200) = NULL,
	@plan_year SMALLINT,
	@plan_month TINYINT,
	@qp_id TINYINT = 2
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON	
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @status_add TINYINT = 13
	
	IF @plan_month < 1
	   OR @plan_month > 12
	BEGIN
	    RAISERROR('Некорректный месяц %d', 16, 1, @plan_month)
	    RETURN
	END
	
	IF @plan_year < 2015
	BEGIN
	    RAISERROR('Некорректный год %d', 16, 1, @plan_year)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN oa_com.sketch_id IS NULL THEN 'У эскиза не указана комплектация'
	      	                   WHEN oa_ts.sketch_id IS NULL THEN 'У эскиза не указан ни один размер'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sc.sketch_id
			      	FROM	Products.SketchCompleting sc
			      	WHERE	sc.sketch_id = s.sketch_id
			      	ORDER BY
			      		sc.sc_id
			      ) oa_com
			OUTER APPLY (
	      			SELECT	TOP(1) sts.sketch_id
	      			FROM	Products.SketchTechSize sts
	      			WHERE	sts.sketch_id = s.sketch_id
				  ) oa_ts
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'Этот эскиз уже в плане со статусом (' + ps.ps_name + ') добавил сотрудник с кодом ' + CAST(sp.create_employee_id AS VARCHAR(10)) + ' / ' 
	      	+ CONVERT(VARCHAR(20), sp.create_dt, 121)
	FROM	Planing.SketchPlan sp   
			LEFT JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id
	WHERE	sp.sketch_id = @sketch_id
			AND	sp.ps_id = @status_add
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритета с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Planing.SketchPlan
		  (
		    sketch_id,
		    ps_id,
		    create_employee_id,
		    create_dt,
		    employee_id,
		    dt,
		    comment,
		    plan_year, 
		    plan_month,
		    qp_id
		  )OUTPUT	INSERTED.sp_id,
		   		INSERTED.sketch_id,
		   		INSERTED.ps_id,
		   		INSERTED.employee_id,
		   		INSERTED.dt,
		   		INSERTED.comment
		   INTO	History.SketchPlan (
		   		sp_id,
		   		sketch_id,
		   		ps_id,
		   		employee_id,
		   		dt,
		   		comment
		   	)
		VALUES
		  (
		    @sketch_id,
		    @status_add,
		    @employee_id,
		    @dt,
		    @employee_id,
		    @dt,
		    @comment,
		    @plan_year,
		    @plan_month,
		    @qp_id
		  )
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
	