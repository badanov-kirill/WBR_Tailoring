CREATE PROCEDURE [Planing].[SketchPrePlan_TechnologicalSequenceWork_Set]
	@start_dt DATE,
	@finish_dt DATE,
	@data_tab Planing.TechSeqWork READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @error_text VARCHAR(MAX)
	
	IF @start_dt IS NULL
	BEGIN
	    RAISERROR('Не задана дата нач. периода', 16, 1)
	    RETURN
	END
	
	IF @finish_dt IS NULL
	BEGIN
	    RAISERROR('Не задана дата кон. периода', 16, 1)
	    RETURN
	END
	
	IF @start_dt >= @finish_dt
	BEGIN
	    RAISERROR('Неверные даты', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sppts.sppts_id IS NULL THEN 'Работы в последовательности с кодом ' + CAST(dt.id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spp.plan_dt > @finish_dt OR spp.plan_dt < @start_dt THEN 'Присутствуют модели, не входящие в заданный период.'
	      	                   WHEN dt.office_id IS NULL OR os.office_id IS NULL THEN 'Присутствуют работы без указания офиса'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts   
			INNER JOIN	Planing.SketchPrePlan spp
				ON	spp.spp_id = sppts.spp_id
				ON	sppts.sppts_id = dt.id
			LEFT JOIN Settings.OfficeSetting os ON os.office_id = dt.office_id
	WHERE	sppts.sppts_id IS NULL
			OR	spp.plan_dt > @finish_dt
			OR	spp.plan_dt < @start_dt
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.id IS NULL THEN 'В переданных данных не все работы моделей в периоде распределены'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.SketchPrePlan spp   
			INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
				ON	sppts.spp_id = spp.spp_id   
			LEFT JOIN	@data_tab dt
				ON	sppts.sppts_id = dt.id
	WHERE	spp.plan_dt >= @start_dt
			AND	spp.plan_dt <= @finish_dt
			AND	dt.id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	d
		FROM	Planing.SketchPrePlan_TechnologicalSequenceWork d   
				INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
					ON	sppts.sppts_id = d.sppts_id   
				INNER JOIN	Planing.SketchPrePlan spp
					ON	spp.spp_id = sppts.spp_id
		WHERE	spp.plan_dt >= @start_dt
				AND	spp.plan_dt <= @finish_dt
		
		INSERT INTO Planing.SketchPrePlan_TechnologicalSequenceWork
			(
				sppts_id,
				work_dt, 
				office_id,
				work_time
			)
		SELECT	dt.id,
				dt.work_dt,
				dt.office_id,
				dt.work_time
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