CREATE PROCEDURE [Planing].[PlantLoadingPlan_Del]
	@spcv_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND plp.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) +
	      	                        ' нет в плане.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.PlantLoadingPlan plp
				ON	plp.spcv_id = spcv.spcv_id
				ON	spcv.spcv_id = v.spcv_id  
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DELETE	pltsw
		FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork pltsw   
				INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
					ON	plpts.plpts_id = pltsw.plpts_id
		WHERE	plpts.spcv_id = @spcv_id
		
		DELETE	
		FROM	Planing.PlantLoadingPlan
		WHERE	spcv_id = @spcv_id
		
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