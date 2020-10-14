CREATE PROCEDURE [Manufactory].[GetTaskSample]
	@employee_id INT,
	@office_id INT,
	@ct_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @task_sample_id INT
	DECLARE @st_priority TINYINT = 3
	
	SELECT	@task_sample_id = ts.task_sample_id
	FROM	Manufactory.TaskSample ts
	WHERE	((ts.pattern_employee_id = @employee_id AND ts.pattern_end_of_work_dt IS NULL) OR (ts.cut_employee_id = @employee_id AND ts.cut_end_of_work_dt IS NULL))
			AND	ts.is_deleted = 0
			AND ts.is_stm = 0
	
	BEGIN TRY
		IF @task_sample_id IS NULL
		BEGIN
		    UPDATE	vt
		    SET 	vt.pattern_employee_id = CASE 
		        	                              WHEN vt.fl = 0 THEN vt.pattern_employee_id
		        	                              ELSE @employee_id
		        	                         END,
		    		vt.pattern_begin_work_dt = CASE 
		    		                                WHEN vt.fl = 0 THEN vt.pattern_begin_work_dt
		    		                                ELSE @dt
		    		                           END,
		    		vt.cut_employee_id = CASE 
		    		                          WHEN vt.fl = 1 THEN vt.cut_employee_id
		    		                          ELSE @employee_id
		    		                     END,
		    		vt.cut_begin_work_dt = CASE 
		    		                            WHEN vt.fl = 1 THEN vt.cut_begin_work_dt
		    		                            ELSE @dt
		    		                       END,
		    		@task_sample_id = vt.task_sample_id
		    FROM	(
		        		SELECT	TOP(1) ts.task_sample_id,
		        				ts.pattern_employee_id,
		        				ts.pattern_begin_work_dt,
		        				ts.pattern_end_of_work_dt,
		        				ts.cut_employee_id,
		        				ts.cut_begin_work_dt,
		        				ts.cut_end_of_work_dt,
		        				CASE 
		        				     WHEN (ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_employee_id IS NULL) THEN 0
		        				     ELSE 1
		        				END fl
		        		FROM	Manufactory.TaskSample ts
		        				OUTER APPLY (
		        				      			SELECT	TOP(1) 1 tp
		        				      			FROM	Manufactory.[Sample] s
		        				      			WHERE	s.task_sample_id = ts.task_sample_id
		        				      					AND	s.st_id = @st_priority
		        							  ) oa		  
		        		WHERE	((ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_employee_id IS NULL) OR ts.pattern_employee_id IS NULL)
		        				AND	ts.is_deleted = 0
		        				AND	ts.office_id = @office_id
		        				AND	ts.ct_id = @ct_id
		        				AND	NOT EXISTS(
		        				   		SELECT	1
		        				   		FROM	Manufactory.TaskSample ts2
		        				   		WHERE	((ts2.pattern_employee_id = @employee_id AND ts2.pattern_end_of_work_dt IS NULL) OR (ts2.cut_employee_id = @employee_id AND ts2.cut_end_of_work_dt IS NULL))
		        				   				AND	ts2.is_deleted = 0
		        				   				AND ts2.is_stm = 0
		        				)
		        				AND ts.problem_dt IS NULL
		        				AND ts.is_stm = 0
		        				AND ts.slicing_dt IS NOT NULL
		        		ORDER BY
		        			CASE 
		        			     WHEN ts.pattern_end_of_work_dt IS NOT NULL AND ts.cut_employee_id IS NULL THEN 0
		        		    ELSE 1
		        		    END ASC,
		        		    ts.proirity_level DESC,
		        		    CASE 
		        			     WHEN oa.tp IS NOT NULL THEN 0
		        			     ELSE 1
		        			END ASC,
		        			ts.qp_id ASC,
		        			ts.task_sample_id ASC
		        	) vt
		END 	
		
		SELECT	ts.task_sample_id,
				s.sample_id,
				ct.ct_name,
				s.sketch_id,
				st.st_name,
				tsz.ts_name,
				ISNULL(sk.pattern_name, sk.sa_local) sa,
				an.art_name,
				sj.subject_name,
				ts.employee_id,
				s.comment,
				CASE 
				     WHEN ts.pattern_end_of_work_dt IS NULL THEN 'Лекала'
				     ELSE 'Крой'
				END job_type,
				s.pattern_perimeter, 
				s.cut_perimeter
		FROM	Manufactory.TaskSample ts    
				INNER JOIN	Manufactory.[Sample] s
					ON	s.task_sample_id = ts.task_sample_id   
				INNER JOIN	Manufactory.SampleType st
					ON	st.st_id = s.st_id   
				LEFT JOIN	Products.TechSize tsz
					ON	tsz.ts_id = s.ts_id   
				INNER JOIN	Products.Sketch sk
					ON	sk.sketch_id = s.sketch_id   
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = sk.art_name_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = sk.subject_id
				INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = s.ct_id
		WHERE	ts.task_sample_id = @task_sample_id
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