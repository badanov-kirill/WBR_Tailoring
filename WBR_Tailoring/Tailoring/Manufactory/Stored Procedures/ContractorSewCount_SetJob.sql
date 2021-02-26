CREATE PROCEDURE [Manufactory].[ContractorSewCount_SetJob]
	@spcv_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (spcvts_id INT, cnt INT)
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = v.spcv_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	;
	WITH cte AS (
		SELECT	ml.value('@spcvts[1]', 'int') spcvts_id,
				ml.value('@cnt[1]', 'smallint') cnt
		FROM	@data_xml.nodes('root/det')x(ml)
	) 
	INSERT INTO @data_tab
		(
			spcvts_id,
			cnt
		)
	SELECT	c.spcvts_id,
			SUM(c.cnt)     cnt
	FROM	cte            c
	GROUP BY
		c.spcvts_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvt.spcvts_id IS NULL THEN 'Размера цветоварианта с идентификатором ' + CAST(dt.spcvts_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN spcvt.spcv_id != @spcv_id THEN 'Размер другого цветоварианта, обратитесь к разработчику.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = dt.spcvts_id
	WHERE	spcvt.spcvts_id IS NULL
			OR	spcvt.spcv_id != @spcv_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvt.cut_cnt_for_job < ISNULL(oa.cnt, 0) + ISNULL(oa_contr.sew_count, 0) THEN 'На размер ' +
	      	                        ts.ts_name + ' раскроено ' + CAST(spcvt.cut_cnt_for_job AS VARCHAR(10)) 
	      	                        + ' уже выполнено ' + CAST(ISNULL(oa_contr.sew_count, 0) AS VARCHAR(10))
	      	                        + ', и указывается ' + CAST(ISNULL(oa.cnt, 0) AS VARCHAR(10)) + '. Нельзя назначать больше чем раскроено.'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			OUTER APPLY (
			      	SELECT	SUM(dt.cnt)     cnt
			      	FROM	@data_tab       dt
			      	WHERE	dt.spcvts_id = spcvt.spcvts_id
			      ) oa
	OUTER APPLY (
	      	SELECT	SUM(csc.cnt) sew_count
	      	FROM	Manufactory.ContractorSewCount csc
	      	WHERE	csc.spcvts_id = spcvt.spcvts_id
	      ) oa_contr
	WHERE	spcvt.spcv_id = @spcv_id
			AND	spcvt.cut_cnt_for_job < ISNULL(oa.cnt, 0) + ISNULL(oa_contr.sew_count, 0)
			AND	ISNULL(oa.cnt, 0) > 0		
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	BEGIN TRY
		INSERT INTO Manufactory.ContractorSewCount
			(
				spcvts_id,
				cnt,
				employee_id,
				dt
			)
		SELECT	dt.spcvts_id,
				dt.cnt,
				@employee_id,
				@dt
		FROM	@data_tab dt
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