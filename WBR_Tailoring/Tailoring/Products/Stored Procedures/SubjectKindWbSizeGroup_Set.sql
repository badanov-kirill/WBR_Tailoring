CREATE PROCEDURE [Products].[SubjectKindWbSizeGroup_Set]
	@subject_id INT,
	@kind_id INT,
	@wb_size_group_id INT,
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
	   	FROM	Products.Kind k
	   	WHERE	k.kind_id = @kind_id
	   )
	BEGIN
	    RAISERROR('Пола с кодом %d не существует', 16, 1, @kind_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.WbSizeGroup wsg
	   	WHERE	wsg.wb_size_group_id = @wb_size_group_id
	   )
	BEGIN
	    RAISERROR('Группы размеров с кодом %d не существует', 16, 1, @wb_size_group_id)
	    RETURN
	END
	
	BEGIN TRY
		MERGE Products.SubjectKindWbSizeGroup t
		USING (
		      	SELECT	@subject_id      subject_id,
		      			@kind_id         kind_id,
		      			@wb_size_group_id wb_size_group_id,
		      			@dt              dt,
		      			@employee_id     employee_id
		      ) s
				ON t.subject_id = s.subject_id
				AND t.kind_id = s.kind_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	wb_size_group_id     = s.wb_size_group_id,
		     		dt                   = s.dt,
		     		employee_id          = s.employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		subject_id,
		     		kind_id,
		     		wb_size_group_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.subject_id,
		     		s.kind_id,
		     		s.wb_size_group_id,
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