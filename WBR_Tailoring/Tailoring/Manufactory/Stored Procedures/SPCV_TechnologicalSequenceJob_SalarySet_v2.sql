CREATE PROCEDURE [Manufactory].[SPCV_TechnologicalSequenceJob_SalarySet_v2]
	@data_tab Manufactory.InSalaryTab READONLY,
	@salary_period_year SMALLINT,
	@salary_period_mont TINYINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @salary_period_id INT
	
	IF @salary_period_year < 2016
	BEGIN
	    RAISERROR('Некорректный период', 16, 1)
	    RETURN
	END
	
	IF @salary_period_mont < 1
	   OR @salary_period_mont > 12
	BEGIN
	    RAISERROR('Некорректный период', 16, 1)
	    RETURN
	END
	
	INSERT INTO Salary.SalaryPeriod
		(
			salary_year,
			salary_month,
			close_period_dt,
			close_period_employee_id
		)
	SELECT	@salary_period_year,
			@salary_period_mont,
			NULL,
			NULL
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Salary.SalaryPeriod sp
	     		WHERE	sp.salary_year = @salary_period_year
	     				AND	sp.salary_month = @salary_period_mont
	     	)
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.close_period_dt IS NOT NULL THEN 'Зарплатный период закрыт, переносить работы в него нельзя'
	      	                   ELSE NULL
	      	              END,
			@salary_period_id = sp.salary_period_id
	FROM	Salary.SalaryPeriod sp
	WHERE	sp.salary_year = @salary_period_year
			AND	sp.salary_month = @salary_period_mont
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @salary_period_id IS NULL
	BEGIN
	    RAISERROR('Зарплатного периода не существует, обратитесь к разработчику', 16, 1)
	    RETURN
	END
		
	SELECT	@error_text = CASE 
	      	                   WHEN dt.stsj_id IS NULL THEN 'Некорректный хмл.'
	      	                   WHEN dt.stsj_id IS NOT NULL AND stsj.stsj_id IS NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN stsj.stsj_id IS NOT NULL AND ISNULL(dt.cnt, 0) = 0 THEN 'Неверный хмл, количество 0'
	      	                   WHEN stsj.stsj_id IS NOT NULL AND ISNULL(dt.amount, 0) = 0 THEN 'Неверный хмл, сумма 0'
	      	                   WHEN stsj.salary_close_dt IS NOT NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' уже закрыто.'
	      	                   WHEN dt.stsj_id IS NOT NULL AND stsj.close_dt IS NULL THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' не подтверждено мастером.'
	      	                   WHEN dt.cnt > stsj.close_cnt THEN 'Задание в работу с кодом ' + CAST(dt.stsj_id AS VARCHAR(10)) +
	      	                        ' переносится в ЗП больше чем подтверждено мастером.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
				ON	stsj.stsj_id = dt.stsj_id
	WHERE	dt.stsj_id IS NULL
			OR	stsj.stsj_id IS NULL
			OR	ISNULL(dt.cnt, 0) = 0
			OR	ISNULL(dt.amount, 0) = 0
			OR dt.cnt > stsj.close_cnt
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	SET @error_text = (
	    	SELECT	sj.subject_name + ' ' + an.art_name + ' (' + pa.sa + pan.sa + ') /' + ts.ts_name + '| № ' + CAST(sts.operation_range AS VARCHAR(10)) + ' ' +
	    	      	ta.ta_name 
	    	      	+ ' / ' + e.element_name + ' | ' + eq.equipment_name + '. Сдано ' + CAST(ISNULL(ready.cnt_ready, 0) + ISNULL(ready_contr.sew_count, 0) AS VARCHAR(10)) + ' меньше, чем перенесено в зп ' +
	    	      	FORMAT(ISNULL(salary.cnt_salary, '0'), '0.00') 
	    	      	+ ' и переносится ' + CAST(ISNULL(in_salary.cnt_in_salary, '0') AS VARCHAR(10)) + CHAR(10)
	    	FROM	Planing.SketchPlanColorVariantTS spcvt   
	    			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
	    				ON	spcvt.spcv_id = sts.spcv_id   
	    			INNER JOIN	(SELECT	stsj.spcvts_id,
	    			    	     	 		stsj.sts_id,
	    			    	     	 		SUM(dt.cnt) cnt_in_salary
	    			    	     	 FROM	@data_tab dt   
	    			    	     	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj
	    			    	     	 			ON	stsj.stsj_id = dt.stsj_id
	    			    	     	 GROUP BY
	    			    	     	 	stsj.spcvts_id,
	    			    	     	 	stsj.sts_id
	    								)in_salary
	    				ON	in_salary.spcvts_id = spcvt.spcvts_id
	    				AND	in_salary.sts_id = sts.sts_id   
	    			LEFT JOIN	(SELECT	c.spcvts_id,
	    			    	    	 		COUNT(1) cnt_ready
	    			    	    	 FROM	Manufactory.ProductUnicCode puc   
	    			    	    	 		INNER JOIN	Manufactory.Cutting c
	    			    	    	 			ON	c.cutting_id = puc.cutting_id
	    			    	    	 WHERE	puc.operation_id IN (8, 4, 3, 1, 6)
	    			    	    	 GROUP BY
	    			    	    	 	c.spcvts_id)ready
	    				ON	ready.spcvts_id = spcvt.spcvts_id
	    			OUTER APPLY (
			      					SELECT	SUM(csc.cnt) sew_count
			      					FROM	Manufactory.ContractorSewCount csc
			      					WHERE	csc.spcvts_id = spcvt.spcvts_id
								  ) ready_contr   
	    			LEFT JOIN	(SELECT		stsj2.sts_id,
	    									stsj2.spcvts_id,
	    			    	    	 		SUM(stsjis.cnt) cnt_salary
	    			    	    	 FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis   
	    			    	    	 		INNER JOIN	Manufactory.SPCV_TechnologicalSequenceJob stsj2
	    			    	    	 			ON	stsj2.stsj_id = stsjis.stsj_id
	    			    	    	 GROUP BY
	    			    	    	 	stsj2.sts_id,
	    								stsj2.spcvts_id)salary
	    				ON	salary.sts_id = sts.sts_id AND salary.spcvts_id = spcvt.spcvts_id   
	    			INNER JOIN	Planing.SketchPlanColorVariant spcv
	    				ON	spcv.spcv_id = spcvt.spcv_id   
	    			INNER JOIN	Products.ProdArticleNomenclature pan
	    				ON	pan.pan_id = spcv.pan_id   
	    			INNER JOIN	Products.ProdArticle pa
	    				ON	pa.pa_id = pan.pa_id   
	    			INNER JOIN	Products.Sketch s
	    				ON	s.sketch_id = pa.sketch_id   
	    			INNER JOIN	Products.[Subject] sj
	    				ON	sj.subject_id = s.subject_id   
	    			INNER JOIN	Products.ArtName an
	    				ON	an.art_name_id = s.art_name_id   
	    			INNER JOIN	Products.TechSize ts
	    				ON	ts.ts_id = spcvt.ts_id   
	    			INNER JOIN	Technology.TechAction ta
	    				ON	ta.ta_id = sts.ta_id   
	    			INNER JOIN	Technology.Element e
	    				ON	e.element_id = sts.element_id   
	    			INNER JOIN	Technology.Equipment eq
	    				ON	eq.equipment_id = sts.equipment_id
	    			LEFT JOIN Manufactory.SketchSalaryExecution sse
	    				ON sse.sketch_id = s.sketch_id
	    	WHERE	ISNULL(salary.cnt_salary, 0) + ISNULL(in_salary.cnt_in_salary, 0) > ISNULL(ready.cnt_ready, 0) + ISNULL(ready_contr.sew_count, 0)*1.001
	    			AND sse.sketch_id IS NULL
	    	FOR XML	PATH('')
	    )
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 	
		
		MERGE Manufactory.SPCV_TechnologicalSequenceJobInSalary t
		USING (
		      	SELECT	dt.stsj_id,
		      			@salary_period_id salary_period_id,
		      			CASE WHEN dt.cnt + ISNULL(v.cnt, 0) + 0.6 > ISNULL(stsj.close_cnt, stsj.plan_cnt) 
		      				THEN  ISNULL(stsj.close_cnt, stsj.plan_cnt) - ISNULL(v.cnt, 0)
		      				ELSE dt.cnt
		      			END cnt,
		      			CASE WHEN dt.cnt + ISNULL(v.cnt, 0) + 0.6 > ISNULL(stsj.close_cnt, stsj.plan_cnt) 
		      				THEN (dt.amount/dt.cnt)*(ISNULL(stsj.close_cnt, stsj.plan_cnt) - ISNULL(v.cnt, 0))
		      				ELSE dt.amount
		      			END amount,
		      			@dt              dt,
		      			@employee_id     employee_id
		      	FROM	@data_tab        dt
		      	INNER JOIN Manufactory.SPCV_TechnologicalSequenceJob stsj 
		      		ON stsj.stsj_id = dt.stsj_id
		      	LEFT JOIN (
		      	           	SELECT	stsjis.stsj_id,
		      	           			SUM(stsjis.cnt) cnt
		      	           	FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
		      	           	GROUP BY
		      	           		stsjis.stsj_id
		      	           )v ON v.stsj_id = stsj.stsj_id
		      ) s
				ON t.stsj_id = s.stsj_id
				AND t.salary_period_id = s.salary_period_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	t.cnt = t.cnt + s.cnt,
		     		t.amount = t.amount + s.amount,
		     		t.dt = s.dt,
		     		t.employee_id = s.employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		stsj_id,
		     		salary_period_id,
		     		cnt,
		     		amount,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.stsj_id,
		     		s.salary_period_id,
		     		s.cnt,
		     		s.amount,
		     		s.dt,
		     		s.employee_id
		     	);
		
		UPDATE	j
		SET 	j.salary_close_dt = @dt,
				j.salary_close_employee_id = @employee_id
		FROM	Manufactory.SPCV_TechnologicalSequenceJob j
				INNER JOIN	(
				    		SELECT	stsjis.stsj_id,
				    				SUM(stsjis.cnt) cnt_salary
				    		FROM	Manufactory.SPCV_TechnologicalSequenceJobInSalary stsjis
				    		WHERE	EXISTS(
				    		     		SELECT	1
				    		     		FROM	@data_tab dt2
				    		     		WHERE	dt2.stsj_id = stsjis.stsj_id
				    		     	)
				    		GROUP BY
				    			stsjis.stsj_id
				    	)salary
					ON	salary.stsj_id = j.stsj_id
		WHERE	EXISTS(
		     		SELECT	1
		     		FROM	@data_tab dt
		     		WHERE	dt.stsj_id = j.stsj_id
		     	)
				AND	j.close_cnt <= salary.cnt_salary + 0.01
				AND	j.salary_close_dt IS NULL 
		
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
GO	