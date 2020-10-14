CREATE PROCEDURE [Planing].[PlantLoadingPlan_TechnologicalSequenceWork_Set]
	@data_tab Planing.TechSeqWork_v2 READONLY,
	@launch_dt DATE,
	@office_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN plpts.plpts_id IS NULL THEN 'Работы в последовательности с кодом' + CAST(dt.id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN plp.spcv_id IS NOT NULL THEN 'Цветовариант с кодом ' + CAST(plp.spcv_id AS VARCHAR(10)) + ' уже в плане'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
				ON	plpts.plpts_id = dt.id   
			LEFT JOIN	Planing.PlantLoadingPlan plp
				ON	plp.spcv_id = plpts.spcv_id
	WHERE	plpts.plpts_id IS NULL
			OR	plp.spcv_id IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.id IS NULL THEN 'В переданных данных не все работы моделей распределены'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.PlantLoadingPlan_TechnologicalSequence plpts   
			LEFT JOIN	@data_tab dt
				ON	plpts.plpts_id = dt.id
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	@data_tab dt   
	     				INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts2
	     					ON	plpts2.plpts_id = dt.id
	     		WHERE	plpts2.spcv_id = plpts.spcv_id
	     	)
			AND	dt.id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Planing.PlantLoadingPlan
			(
				spcv_id,
				create_employee_id,
				create_dt,
				launch_dt,
				finish_dt,
				labor_costs,
				office_id,
				qty
			)
		SELECT	plpts.spcv_id,
				@employee_id,
				@dt,
				@launch_dt,
				MAX(dt.work_dt),
				SUM(dt.work_time),
				@office_id,
				MAX(ISNULL(spcv.corrected_qty, spcv.qty))
		FROM	@data_tab dt   
				INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
					ON	plpts.plpts_id = dt.id
				INNER JOIN Planing.SketchPlanColorVariant spcv
					ON spcv.spcv_id = plpts.spcv_id
		GROUP BY
			plpts.spcv_id
		
		INSERT INTO Planing.PlantLoadingPlan_TechnologicalSequenceWork
			(
				plpts_id,
				work_dt,
				employee_id,
				work_time,
				office_id
			)
		SELECT	dt.id,
				dt.work_dt,
				dt.employee_id,
				dt.work_time,
				dt.office_id
		FROM	@data_tab dt
		
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 