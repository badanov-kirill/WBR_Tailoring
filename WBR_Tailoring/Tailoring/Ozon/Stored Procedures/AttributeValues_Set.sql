CREATE PROCEDURE [Ozon].[AttributeValues_Set]
	@category_id BIGINT,
	@attribute_id BIGINT,
	@data Ozon.AttributeValuesType READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Ozon.AttributeValues
			(
				av_id,
				av_value,
				is_used
			)
		SELECT	dt.av_id,
				ISNULL(dt.av_value, '')     av_value,
				1
		FROM	@data                       dt
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Ozon.AttributeValues av
		     		WHERE	av.av_id = dt.av_id
		     	)   
		
		DELETE	Ozon.CategoriesAttributeValues
		WHERE	category_id = @category_id
				AND	attribute_id = @attribute_id
		
		INSERT INTO Ozon.CategoriesAttributeValues
			(
				category_id,
				attribute_id,
				av_id
			)
		SELECT	@category_id,
				@attribute_id,
				dt.av_id
		FROM	@data dt
		
		--MERGE Ozon.AttributeValues t
		--USING (
		--      	SELECT	dt.av_id,
		--      			ISNULL(dt.av_value, '') av_value
		--      	FROM	@data dt
		--      ) s
		--		ON t.av_id = s.av_id
		--WHEN MATCHED AND t.av_value != s.av_value THEN
		--     UPDATE
		--     SET 	t.av_value = s.av_value
		--WHEN NOT MATCHED THEN
		--     INSERT
		--     	(
		--     		av_id,
		--     		av_value
		--     	)
		--     VALUES
		--     	(
		--     		s.av_id,
		--     		s.av_value
		--     	);
		
		--;WITH cte_Target AS (
		--	SELECT	cav.category_id,
		--			cav.attribute_id,
		--			cav.av_id
		--	FROM	Ozon.CategoriesAttributeValues cav
		--	WHERE	cav.category_id = @category_id
		--			AND	cav.attribute_id = @attribute_id
		--)
		--MERGE cte_Target t
		--USING (
		--      	SELECT	DISTINCT @category_id category_id,
		--      			@attribute_id     attribute_id,
		--      			dt.av_id
		--      	FROM	@data             dt
		--      ) s
		--		ON t.av_id = s.av_id
		--WHEN NOT MATCHED BY TARGET THEN
		--     INSERT
		--     	(
		--     		category_id,
		--     		attribute_id,
		--     		av_id
		--     	)
		--     VALUES
		--     	(
		--     		s.category_id,
		--     		s.attribute_id,
		--     		s.av_id
		--     	)
		--WHEN NOT MATCHED BY SOURCE THEN
		--     DELETE	;
		
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
