CREATE PROCEDURE [Products].[SubjectBrandTPGroup_Set]
	@subject_id INT,
	@brand_id INT,
	@tpgroup_id INT,
	@kind_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.[Subject] s
	   	WHERE	s.subject_id = @subject_id
	   )
	BEGIN
	    RAISERROR('Предмета с кодом %d не существует', 16, 1, @subject_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Brand b
	   	WHERE	b.brand_id = @brand_id
	   )
	BEGIN
	    RAISERROR('Бренда с кодом %d не существует', 16, 1, @brand_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.Kind k
	   	WHERE	k.kind_id = @kind_id
	   )
	BEGIN
	    RAISERROR('Пола с кодом %d не существует', 16, 1, @kind_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.TPGroup tpg
	   	WHERE	tpg.tpgroup_id = @tpgroup_id
	   )
	BEGIN
	    RAISERROR('Группы размеров с кодом %d не существует', 16, 1, @tpgroup_id)
	    RETURN
	END
	
	BEGIN TRY
		MERGE Products.SubjectBrandTPGroup t
		USING (
		      	SELECT	@subject_id      subject_id,
		      			@brand_id        brand_id,
		      			@kind_id		 kind_id,
		      			@tpgroup_id      tpgroup_id,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON t.subject_id = s.subject_id
				AND t.brand_id = s.brand_id
				AND t.kind_id = s.kind_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	tpgroup_id      = s.tpgroup_id,
		     		dt              = s.dt,
		     		employee_id     = s.employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		subject_id,
		     		brand_id,
		     		kind_id,
		     		tpgroup_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.subject_id,
		     		s.brand_id,
		     		s.kind_id,
		     		s.tpgroup_id,
		     		s.dt,
		     		s.employee_id
		     	);
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