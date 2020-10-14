CREATE PROCEDURE [Wildberries].[WB_Subjects_Set]
	@template_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (wb_subject_id INT, wb_subject_name VARCHAR(100), wb_subject_parent_id INT, wb_subject_parent_name VARCHAR(100))
	
	INSERT INTO @data_tab
		(
			wb_subject_id,
			wb_subject_name,
			wb_subject_parent_id,
			wb_subject_parent_name
		)
	SELECT	ml.value('@id[1]', 'int'),
			ml.value('@name[1]', 'varchar(100)'),
			ml.value('@pid[1]', 'int'),
			ml.value('@pname[1]', 'varchar(100)')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		MERGE Wildberries.WB_SubjectParensts t
		USING (
		      	SELECT	dt.wb_subject_parent_id,
		      			MAX(dt.wb_subject_parent_name) wb_subject_parent_name
		      	FROM	@data_tab dt
		      	GROUP BY
		      		dt.wb_subject_parent_id
		      ) s
				ON t.wb_subject_parent_id = s.wb_subject_parent_id
		WHEN MATCHED AND s.wb_subject_parent_name != t.wb_subject_parent_name THEN 
		     UPDATE	
		     SET 	wb_subject_parent_name = s.wb_subject_parent_name,
		     		dt = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		wb_subject_parent_id,
		     		wb_subject_parent_name,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.wb_subject_parent_id,
		     		s.wb_subject_parent_name,
		     		@dt
		     	);
		
		MERGE Wildberries.WB_Subjects t
		USING @data_tab s
				ON s.wb_subject_id = t.wb_subject_id
		WHEN MATCHED AND s.wb_subject_name != t.wb_subject_name OR t.wb_subject_parent_id != t.wb_subject_parent_id OR t.is_deleted = 1 THEN 
		     UPDATE	
		     SET 	wb_subject_name          = s.wb_subject_name,
		     		is_deleted               = 0,
		     		wb_subject_parent_id     = t.wb_subject_parent_id,
		     		dt                       = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		wb_subject_id,
		     		wb_subject_name,
		     		is_deleted,
		     		wb_subject_parent_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.wb_subject_id,
		     		s.wb_subject_name,
		     		0,
		     		s.wb_subject_parent_id,
		     		@dt
		     	);
		
		WITH cte_target AS (
			SELECT	ts.template_id,
					ts.wb_subject_id
			FROM	Wildberries.TemplatesSubjects ts
			WHERE	ts.template_id = @template_id
		)
		MERGE cte_target t
		USING @data_tab s
				ON s.wb_subject_id = t.wb_subject_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		template_id,
		     		wb_subject_id
		     	)
		     VALUES
		     	(
		     		@template_id,
		     		s.wb_subject_id
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
	