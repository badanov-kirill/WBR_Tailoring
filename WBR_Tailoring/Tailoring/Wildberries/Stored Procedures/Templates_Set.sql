CREATE PROCEDURE [Wildberries].[Templates_Set]
@data_xml XML
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (template_id INT, template_name VARCHAR(200))
	
	INSERT INTO @data_tab
		(
			template_id,
			template_name
		)
	SELECT	ml.value('@id[1]', 'int'),
			ml.value('@name[1]', 'varchar(200)')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	BEGIN TRY
		MERGE Wildberries.Templates t
		USING @data_tab s
				ON s.template_id = t.template_id
		WHEN MATCHED AND (s.template_name != t.template_name OR t.id_deleted = 1) THEN 
		     UPDATE	
		     SET 	template_name     = s.template_name,
		     		id_deleted        = 0,
		     		dt                = @dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		template_id,
		     		template_name,
		     		id_deleted,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.template_id,
		     		s.template_name,
		     		0,
		     		@dt
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.id_deleted = 0 THEN 
		     UPDATE	
		     SET 	id_deleted     = 0,
		     		dt             = @dt;
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
	