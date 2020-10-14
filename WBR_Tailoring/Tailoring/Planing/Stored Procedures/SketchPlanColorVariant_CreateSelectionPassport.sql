CREATE PROCEDURE [Planing].[SketchPlanColorVariant_CreateSelectionPassport]
	@spcv_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @task_sp_output TABLE (tsp_id INT)
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	
	
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready) THEN 'Статус цветоварианта ' + cvs.cvs_name + ', сбор паспартов запрещен.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @shkrm_tab
	  (
	    shkrm_id
	  )
	SELECT	smr.shkrm_id
	FROM	Warehouse.SHKRawMaterialReserv smr   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id
	WHERE	spcvc.spcv_id = @spcv_id
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@shkrm_tab
	   )
	BEGIN
	    RAISERROR('Нет резервов.', 16, 1)
	    RETURN
	END		      	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Planing.TaskSelectionPassport
		  (
		    create_dt,
		    create_employee_id
		  )OUTPUT	INSERTED.tsp_id
		   INTO	@task_sp_output (
		   		tsp_id
		   	)
		VALUES
		  (
		    @dt,
		    @employee_id
		  )
		
		INSERT INTO Planing.TaskSelectionPassportDetail
		  (
		    tsp_id,
		    shkrm_id,
		    employee_id,
		    dt
		  )
		SELECT	tso.tsp_id,
				st.shkrm_id,
				@employee_id,
				@dt
		FROM	@shkrm_tab st   
				CROSS JOIN	@task_sp_output tso
		
		
		COMMIT TRANSACTION
		
		SELECT	tso.tsp_id,
				smr.shkrm_id,
				rmt.rmt_name,
				cc.color_name,
				smai.frame_width
		FROM	@shkrm_tab smr   
				CROSS JOIN	@task_sp_output tso   
				INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
					ON	smai.shkrm_id = smr.shkrm_id   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = smai.rmt_id   
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = smai.color_id
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
	