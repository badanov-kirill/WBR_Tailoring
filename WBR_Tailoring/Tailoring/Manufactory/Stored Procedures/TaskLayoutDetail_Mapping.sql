CREATE PROCEDURE [Manufactory].[TaskLayoutDetail_Mapping]
	@tl_id INT,
	@layout_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN l.layout_id IS NULL THEN 'Раскладки с кодом ' + CAST(v.layout_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.is_deleted = 1 THEN 'Эскиз с кодом ' + CAST(s.sketch_id AS VARCHAR(10)) + ' удален.'
	      	                   ELSE NULL
	      	              END,
			@sketch_id = s.sketch_id
	FROM	(VALUES(@layout_id))v(layout_id)   
			LEFT JOIN	Manufactory.Layout l   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = l.base_sketch_id
				ON	l.layout_id = v.layout_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN tl.tl_id IS NULL THEN 'Задания с номером ' + CAST(v.tl_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sp.sketch_id != @sketch_id THEN 'У задания и раскладки отличатся эскизы, связывать нельзя'
	      	                   WHEN tld.tld_id IS NOT NULL THEN 'Этот эскиз уже привязан к этому заданию.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@tl_id))v(tl_id)   
			LEFT JOIN	Manufactory.TaskLayout tl   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = tl.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id
				ON	tl.tl_id = v.tl_id
			LEFT JOIN Manufactory.TaskLayoutDetail tld
			ON tld.tl_id = tl.tl_id AND tld.layout_id = @layout_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Manufactory.TaskLayoutDetail
		  (
		    tl_id,
		    layout_id,
		    dt,
		    employee_id
		  )
		VALUES
		  (
		    @tl_id,
		    @layout_id,
		    @dt,
		    @employee_id
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 