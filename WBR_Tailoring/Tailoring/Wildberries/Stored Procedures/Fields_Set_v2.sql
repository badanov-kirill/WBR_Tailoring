CREATE PROCEDURE [Wildberries].[Fields_Set_v2]
	@template_id INT,
	@fields_tab Wildberries.FieldsTab READONLY,
	@fields_locale_name_tab Wildberries.LocaleNameTab READONLY,
	@fields_locale_si_name_tab Wildberries.LocaleNameTab READONLY,
	@required_fields Wildberries.RequiredFields READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	

	DECLARE @required_fields_tab TABLE (wb_subject_id INT, fields_id INT)
	

	
	INSERT INTO @required_fields_tab
		(
			wb_subject_id,
			fields_id
		)
	SELECT	ws.wb_subject_id,
			rf.fields_id
	FROM	@required_fields rf
			INNER JOIN	Wildberries.WB_Subjects ws
				ON	ws.wb_subject_name = rf.wb_subject_name
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		MERGE Wildberries.Fields t
		USING @fields_tab s
				ON s.fields_id = t.fields_id
		WHEN MATCHED AND (
		     	s.fields_name != t.fields_name
		     	OR 
		     	   ISNULL(s.kind_id, 0) != 
		     	   ISNULL(t.kind_id, 0)
		     	OR 
		     	   ISNULL(s.si_name, '') != 
		     	   ISNULL(t.si_name, '')
		     	OR 
		     	   ISNULL(s.is_required, 0) != 
		     	   ISNULL(t.is_required, 0)
		     	OR 
		     	   ISNULL(s.is_readonly, 0) != 
		     	   ISNULL(t.is_readonly, 0)
		     	OR 
		     	   ISNULL(s.regex, '') != 
		     	   ISNULL(t.regex, '')
		     	OR 
		     	   ISNULL(s.header, '') != 
		     	   ISNULL(t.header, '')
		     	OR 
		     	   ISNULL(s.max_count, 0) != 
		     	   ISNULL(t.max_count, 0)
		     	OR t.is_deleted = 1
		     ) THEN 
		     UPDATE	
		     SET 	fields_name     = s.fields_name,
		     		kind_id         = s.kind_id,
		     		si_name         = s.si_name,
		     		is_required     = s.is_required,
		     		is_readonly     = s.is_readonly,
		     		regex           = s.regex,
		     		header          = s.header,
		     		max_count       = s.max_count,
		     		is_deleted      = 0,
		     		dt              = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		fields_id,
		     		fields_name,
		     		kind_id,
		     		si_name,
		     		is_required,
		     		is_readonly,
		     		regex,
		     		header,
		     		max_count,
		     		dt,
		     		is_deleted
		     	)
		     VALUES
		     	(
		     		s.fields_id,
		     		s.fields_name,
		     		s.kind_id,
		     		s.si_name,
		     		s.is_required,
		     		s.is_readonly,
		     		s.regex,
		     		s.header,
		     		s.max_count,
		     		@dt,
		     		0
		     	);
		
		MERGE Wildberries.FieldsLocaleNames t
		USING @fields_locale_name_tab s
				ON s.fields_id = t.fields_id
				AND s.locale_cod = t.locale_cod
		WHEN MATCHED AND s.fields_locale_name != t.fields_locale_name THEN 
		     UPDATE	
		     SET 	fields_locale_name = s.fields_locale_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		fields_id,
		     		locale_cod,
		     		fields_locale_name
		     	)
		     VALUES
		     	(
		     		s.fields_id,
		     		s.locale_cod,
		     		s.fields_locale_name
		     	);
		
		MERGE Wildberries.FieldsLocaleSiNames t
		USING @fields_locale_si_name_tab s
				ON s.fields_id = t.fields_id
				AND s.locale_cod = t.locale_cod
		WHEN MATCHED AND s.fields_locale_name != t.fields_locale_si_name THEN 
		     UPDATE	
		     SET 	fields_locale_si_name = s.fields_locale_name
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		fields_id,
		     		locale_cod,
		     		fields_locale_si_name
		     	)
		     VALUES
		     	(
		     		s.fields_id,
		     		s.locale_cod,
		     		s.fields_locale_name
		     	);
		
		WITH cte_target AS (
			SELECT	tf.template_id,
					tf.fields_id
			FROM	Wildberries.TemplatesFields tf
			WHERE	tf.template_id = @template_id
		)
		MERGE cte_target t
		USING @fields_tab s
				ON s.fields_id = t.fields_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		template_id,
		     		fields_id
		     	)
		     VALUES
		     	(
		     		@template_id,
		     		s.fields_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_target AS (
			SELECT	fr.wb_subject_id,
					fr.fields_id
			FROM	Wildberries.FieldsRequired fr
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@required_fields_tab rft
			     		WHERE	fr.wb_subject_id = rft.wb_subject_id
			     	)
		)
		MERGE cte_target t
		USING @required_fields_tab s
				ON s.wb_subject_id = t.wb_subject_id
				AND s.fields_id = t.fields_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		wb_subject_id,
		     		fields_id
		     	)
		     VALUES
		     	(
		     		s.wb_subject_id,
		     		s.fields_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
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
	
	