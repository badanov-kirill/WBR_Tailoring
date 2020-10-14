CREATE PROCEDURE [Planing].[SketchPrePlan_SetDataByXml]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @data_tab TABLE(spp_id INT PRIMARY KEY CLUSTERED NOT NULL, dt DATE NULL, plan_qty SMALLINT NULL, cv_qty TINYINT NULL)
	
	
	INSERT INTO @data_tab
		(
			spp_id,
			dt,
			plan_qty,
			cv_qty
		)
	SELECT	v.spp_id,
			MAX(v.dt)           dt,
			MAX(v.plan_qty)     plan_qty,
			MAX(v.cv_qty)       cv_qty
	FROM	(SELECT	ml.value('@spp[1]', 'int') spp_id,
	    	 		ml.value('@dt[1]', 'date') dt,
	    	 		ISNULL(ml.value('@qty[1]', 'smallint'), 0) plan_qty,
	    	 		ISNULL(ml.value('@cvqty[1]', 'tinyint'), 0) cv_qty
	    	 FROM	@data_xml.nodes('root/det')x(ml))v
	GROUP BY
		v.spp_id	
	
	SELECT	@error_text = 'Не найдены следующие коды строчек предвартительного плана:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spp_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPrePlan spp
	      					ON	spp.spp_id = dt.spp_id
	      		WHERE	spp.spp_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	--SELECT	@error_text = 'Уже созданы цветоварианты на следующие модели строчек предвартительного плана:' + CHAR(10)
	--      	+ (
	--      		SELECT	sj.subject_name + ' / ' + an.art_name + ' / ' + s.sa + CHAR(10)
	--      		FROM	@data_tab dt   
	--      				INNER JOIN	Planing.SketchPrePlan spp
	--      					ON	spp.spp_id = dt.spp_id
	--      				INNER JOIN Planing.SketchPlan sp
	--      					ON sp.spp_id = spp.spp_id
	--      				INNER JOIN Products.Sketch s
	--      					ON s.sketch_id = spp.sketch_id
	--      				INNER JOIN Products.ArtName an
	--      					ON an.art_name_id = s.art_name_id
	--      				INNER JOIN Products.[Subject] sj
	--      					ON sj.subject_id = s.subject_id	      				
	--      		WHERE	EXISTS (SELECT 1 FROM Planing.SketchPlanColorVariant spcv WHERE spcv.sp_id = sp.sp_id AND spcv.is_deleted = 0)
	--      		FOR XML	PATH('')
	--      	) + CHAR(10)	+ ' необходимо использовать их, или удалить.'
	
	--IF @error_text IS NOT NULL
	--BEGIN
	--    RAISERROR('%s', 16, 1, @error_text)
	--    RETURN
	--END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	spp
		SET 	spp.plan_dt = dt.dt,
				spp.plan_qty = dt.plan_qty,
				spp.cv_qty = dt.cv_qty,
				spp.employee_id = @employee_id,
				spp.dt = @dt
		FROM	Planing.SketchPrePlan spp
				INNER JOIN	@data_tab dt
					ON	dt.spp_id = spp.spp_id
					
		UPDATE	s
		SET 	plan_site_dt = dt.dt 
		FROM	Planing.SketchPrePlan spp
				INNER JOIN	@data_tab dt
					ON	dt.spp_id = spp.spp_id
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = spp.sketch_id	
					
		UPDATE	sp
		SET 	plan_sew_dt = spp.plan_dt,
				plan_month = MONTH(DATEADD(DAY, -60, spp.plan_dt)),
				plan_year = YEAR(DATEADD(DAY, -60, spp.plan_dt)),
				sew_office_id = spp.sew_office_id,
				plan_qty = spp.plan_qty,
				cv_qty = spp.cv_qty
		FROM	Planing.SketchPlan sp
				INNER JOIN	Planing.SketchPrePlan spp
					ON	spp.spp_id = sp.spp_id
				INNER JOIN	@data_tab dt
					ON	dt.spp_id = spp.spp_id		
		
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