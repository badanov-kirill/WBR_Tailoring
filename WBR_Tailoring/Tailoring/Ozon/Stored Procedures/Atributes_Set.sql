CREATE PROCEDURE [Ozon].[Atributes_Set]
	@data Ozon.AttributesType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	INSERT INTO dbo.DataTypes
		(
			data_type_name
		)
	SELECT	DISTINCT ISNULL(dt.data_type_name, '')
	FROM	@data dt
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	dbo.DataTypes dt2
	     		WHERE	dt2.data_type_name = ISNULL(dt.data_type_name, '')
	     	)
	
	INSERT INTO Ozon.AttributesGroups
		(
			oag_id,
			oag_name
		)
	SELECT	dt.oag_id,
			MAX(ISNULL(dt.oag_name, ''))
	FROM	@data dt
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Ozon.AttributesGroups ag
	     		WHERE	ag.oag_id = dt.oag_id
	     	)
	GROUP BY
		dt.oag_id
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Ozon.Attributes t
		USING (
		      	SELECT	dt.attribute_id,
		      			MAX(dt.attribute_name) attribute_name,
		      			MAX(dt.attribute_descr) attribute_descr,
		      			MAX(dtp.data_type_id) data_type_id,
		      			MAX(dt.oag_id) oag_id,
		      			MAX(ISNULL(CAST(dt.is_collection AS INT), 0)) is_collection,
		      			MAX(ISNULL(dt.dictionary_id, 0)) dictionary_id
		      	FROM	@data dt   
		      			LEFT JOIN	dbo.DataTypes dtp
		      				ON	ISNULL(dt.data_type_name, '') = dtp.data_type_name
		      	GROUP BY
		      		dt.attribute_id
		      ) s
				ON t.attribute_id = s.attribute_id
		WHEN MATCHED AND (
		     	t.attribute_name != s.attribute_name
		     	OR t.attribute_descr != s.attribute_descr
		     	OR t.data_type_id != s.data_type_id
		     	OR t.oag_id != s.oag_id
		     	OR t.is_collection != s.is_collection
		     	OR t.dictionary_id != s.dictionary_id
		     ) THEN 
		     UPDATE	
		     SET 	t.attribute_name = s.attribute_name,
		     		t.attribute_descr = s.attribute_descr,
		     		t.data_type_id = s.data_type_id,
		     		t.oag_id = s.oag_id,
		     		t.is_collection = s.is_collection,
		     		t.dictionary_id = s.dictionary_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		attribute_id,
		     		attribute_name,
		     		attribute_descr,
		     		data_type_id,
		     		oag_id,
		     		is_collection,
		     		dictionary_id
		     	)
		     VALUES
		     	(
		     		s.attribute_id,
		     		s.attribute_name,
		     		s.attribute_descr,
		     		s.data_type_id,
		     		s.oag_id,
		     		s.is_collection,
		     		s.dictionary_id
		     	);
		
		WITH cte_Target AS (
			SELECT	ca.category_id,
					ca.attribute_id,
					ca.is_required
			FROM	Ozon.CategoriesAttributes ca
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@data d
			     		WHERE	ca.category_id = d.category_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	dt.category_id,
		      			dt.attribute_id,
		      			MAX(ISNULL(CAST(dt.is_required AS INT), 0)) is_required
		      	FROM	@data dt
		      	GROUP BY
		      		dt.category_id,
		      		dt.attribute_id
		      ) s
				ON t.attribute_id = s.attribute_id
				AND t.category_id = s.category_id
		WHEN MATCHED THEN
			UPDATE 
			SET t.is_required = s.is_required
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		category_id,
		     		attribute_id,
		     		is_required
		     	)
		     VALUES
		     	(
		     		s.category_id,
		     		s.attribute_id,
		     		s.is_required
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
