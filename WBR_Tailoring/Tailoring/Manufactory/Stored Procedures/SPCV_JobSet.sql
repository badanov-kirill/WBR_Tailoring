CREATE PROCEDURE [Manufactory].[SPCV_JobSet]
	@spcv_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (sts_id INT, spcvts_id INT, employee_id INT, plan_cnt SMALLINT)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @is_set_job BIT = 0
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END,
			@is_set_job = CASE 
			                   WHEN spcv.set_job_dt IS NOT NULL THEN 1
			                   ELSE 0
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
		SELECT	ml.value('@sts[1]', 'int') sts_id,
				ml.value('@spcvts[1]', 'int') spcvts_id,
				ml.value('@empl[1]', 'int') employee_id,
				ml.value('@cnt[1]', 'smallint') plan_cnt
		FROM	@data_xml.nodes('root/det')x(ml)
	) 
	INSERT INTO @data_tab
		(
			sts_id,
			spcvts_id,
			employee_id,
			plan_cnt
		)
	SELECT	c.sts_id,
			c.spcvts_id,
			c.employee_id,
			SUM(c.plan_cnt)     plan_cnt
	FROM	cte                 c
	GROUP BY
		c.sts_id,
		c.spcvts_id,
		c.employee_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN sts.sts_id IS NULL THEN 'Работы с идентификатором ' + CAST(dt.sts_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcvt.spcvts_id IS NULL THEN 'Размера цветоварианта с идентификатором ' + CAST(dt.spcvts_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN sts.spcv_id != @spcv_id THEN 'Технология другого цветоварианта, обратитесь к разработчику.'
	      	                   WHEN spcvt.spcv_id != @spcv_id THEN 'Размер другого цветоварианта, обратитесь к разработчику.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = dt.sts_id   
			LEFT JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = dt.spcvts_id
	WHERE	sts.sts_id IS NULL
			OR	spcvt.spcvts_id IS NULL
			OR	sts.spcv_id != @spcv_id
			OR	spcvt.spcv_id != @spcv_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvt.cut_cnt_for_job < oa.plan_cnt THEN 'На операции "' + ta.ta_name + '" элемента "' + e.element_name + '", на размер ' +
	      	                        ts.ts_name + ' раскроено ' + CAST(spcvt.cut_cnt_for_job AS VARCHAR(10)) 
	      	                        + ', а назначено ' + CAST(oa.plan_cnt AS VARCHAR(10)) + '. Нельзя назначать больше чем раскроено.'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.SketchPlanColorVariantTS spcvt   
			INNER JOIN 	Manufactory.SPCV_TechnologicalSequence sts
				ON sts.spcv_id = spcvt.spcv_id 
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = sts.ta_id   
			INNER JOIN	Technology.Element e
				ON	e.element_id = sts.element_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = spcvt.ts_id   
			OUTER APPLY (
			      	SELECT	SUM(ISNULL(stsj.close_cnt, dt.plan_cnt)) plan_cnt
			      	FROM	@data_tab dt   
			      			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
			      				ON	stsj.sts_id = dt.sts_id
			      				AND	stsj.employee_id = dt.employee_id
			      				AND	stsj.spcvts_id = dt.spcvts_id
			      	WHERE	dt.spcvts_id = spcvt.spcvts_id
			      			AND	dt.sts_id = sts.sts_id
			      ) oa
			      WHERE	spcvt.spcv_id = @spcv_id
			AND	spcvt.cut_cnt_for_job < oa.plan_cnt			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @is_set_job = 1
	BEGIN
	    SELECT	@error_text = CASE 
	          	                   WHEN dt.sts_id IS NULL THEN 'На операции "' + ta.ta_name + '" элемента "' + e.element_name +
	          	                        '", на размер, был назначен сотрудник с кодом ' 
	          	                        + CAST(stsj.job_employee_id AS VARCHAR(10)) +
	          	                        ', которого вы пытаетесь удалить, но распределение работ уже закрыто, и уменьшить количество можно только через подтверждение работ.'
	          	                   WHEN dt.plan_cnt IS NOT NULL AND stsj.salary_close_dt IS NOT NULL AND stsj.close_cnt > dt.plan_cnt THEN 'На операции "' + ta.ta_name + '" элемента "' + e.element_name 
	          	                        +
	          	                        '", на размер, сотруднику с кодом ' + CAST(stsj.job_employee_id AS VARCHAR(10)) + ' ' +
	          	                        ', которого вы пытаетесь удалить, но распределение зарплаты уже закрыто.'
	          	                   ELSE NULL
	          	              END
	    FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
	    		INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
	    			ON	sts.sts_id = stsj.sts_id   
	    		INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	    			ON	spcvt.spcvts_id = stsj.spcvts_id   
	    		INNER JOIN	Technology.TechAction ta
	    			ON	ta.ta_id = sts.ta_id   
	    		INNER JOIN	Technology.Element e
	    			ON	e.element_id = sts.element_id   
	    		INNER JOIN	Products.TechSize ts
	    			ON	ts.ts_id = spcvt.ts_id   
	    		LEFT JOIN	@data_tab dt
	    			ON	dt.sts_id = sts.sts_id
	    			AND	dt.spcvts_id = stsj.spcvts_id
	    			AND	stsj.job_employee_id = dt.employee_id
	    WHERE	sts.spcv_id = @spcv_id
	END
	
	BEGIN TRY
		;
		WITH cte_target AS (
			SELECT	stsj.stsj_id,
					stsj.sts_id,
					stsj.spcvts_id,
					stsj.job_employee_id,
					stsj.plan_cnt,
					stsj.dt,
					stsj.employee_id,
					stsj.employee_cnt,
					stsj.close_cnt,
					stsj.close_dt,
					stsj.close_employee_id,
					stsj.salary_close_dt,
					stsj.salary_close_employee_id
			FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	Manufactory.SPCV_TechnologicalSequence sts
			     		WHERE	sts.sts_id = stsj.sts_id
			     				AND	sts.spcv_id = @spcv_id
			     	)
		)
		MERGE cte_target t
		USING @data_tab s
				ON s.sts_id = t.sts_id
				AND s.spcvts_id = t.spcvts_id
				AND s.employee_id = t.job_employee_id
		WHEN MATCHED 
		AND ((t.plan_cnt != s.plan_cnt AND t.close_cnt IS NULL) 
		OR (t.close_cnt < s.plan_cnt) 
		OR (t.close_cnt > s.plan_cnt AND t.salary_close_dt IS NULL)) 		
		THEN 
		     UPDATE	
		     SET 	plan_cnt        = s.plan_cnt,
		     		dt              = @dt,
		     		employee_id     = @employee_id,
		     		employee_cnt	= NULL,
		     		close_cnt	    = NULL,
		     		close_dt        = NULL,
		     		salary_close_dt = NULL,
		     		salary_close_employee_id = NULL
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sts_id,
		     		spcvts_id,
		     		job_employee_id,
		     		plan_cnt,
		     		dt,
		     		employee_id,
		     		employee_cnt,
		     		close_cnt,
		     		close_dt,
		     		close_employee_id
		     	)
		     VALUES
		     	(
		     		s.sts_id,
		     		s.spcvts_id,
		     		s.employee_id,
		     		s.plan_cnt,
		     		@dt,
		     		@employee_id,
		     		NULL,
		     		NULL,
		     		NULL,
		     		NULL
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
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