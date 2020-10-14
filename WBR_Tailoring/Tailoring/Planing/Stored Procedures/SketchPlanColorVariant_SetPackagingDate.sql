CREATE PROCEDURE [Planing].[SketchPlanColorVariant_SetPackagingDate]
	@data_xml XML,
	@deadline_package_dt DATE,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @data_tab TABLE(spcv_id INT PRIMARY KEY CLUSTERED)
	
	
	INSERT INTO @data_tab
		(
			spcv_id
		)
	SELECT	ml.value('@spcv[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = 'Не найдены следующие коды строчек плана:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spcv_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPlanColorVariant spcv
	      					ON	spcv.spcv_id = dt.spcv_id
	      		WHERE	spcv.spcv_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN v.spcv_id IS NULL THEN 'Не корректный XML'
	      	                   WHEN @deadline_package_dt > sp.plan_sew_dt THEN 'У модели ' + an.art_name + ' дата, когда сайта ' + CAST(sp.plan_sew_dt AS VARCHAR(50)) 
	      	                        + '. Дэдлайн упаковки должен быть раньше.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab v   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp   
			INNER JOIN	Products.Sketch s   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id
				ON	s.sketch_id = sp.sketch_id
				ON	sp.sp_id = spcv.sp_id
				ON	spcv.spcv_id = v.spcv_id
	WHERE	spcv.spcv_id IS NULL
			OR	v.spcv_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	spcv
		SET 	spcv.deadline_package_dt = @deadline_package_dt,
				spcv.employee_id = @employee_id,
				spcv.dt = @dt
		FROM	Planing.SketchPlanColorVariant spcv
				INNER JOIN	@data_tab dt
					ON	dt.spcv_id = spcv.spcv_id
		
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