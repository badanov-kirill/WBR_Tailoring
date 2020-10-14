CREATE PROCEDURE [Manufactory].[GetTaskSew]
	@employee_id INT,
	@office_id INT,
	@ct_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @ts_id INT
	DECLARE @st_priority TINYINT = 3
	
	SELECT	@ts_id = ts.ts_id
	FROM	Manufactory.TaskSew ts
	WHERE	ts.sew_employee_id = @employee_id
			AND	ts.sew_end_work_dt IS NULL
			AND	ts.is_deleted = 0
	
	BEGIN TRY
		IF @ts_id IS NULL
		BEGIN
		    UPDATE	vt
		    SET 	vt.sew_employee_id = @employee_id,
		    		vt.sew_begin_work_dt = @dt,
		    		@ts_id = vt.ts_id
		    FROM	(
		        		SELECT	TOP(1) ts.ts_id,
		        				ts.sew_employee_id,
		        				ts.sew_begin_work_dt
		        		FROM	Manufactory.TaskSew ts   
		        				OUTER APPLY (
		        				      	SELECT	TOP(1) CASE 
		        				      	      	            WHEN s.st_id = @st_priority THEN 0
		        				      	      	            ELSE 1
		        				      	      	       END tp,
		        				      			s.task_sample_id,
		        				      			ts2.qp_id,
		        				      			ts2.proirity_level
		        				      	FROM	Manufactory.TaskSewSample tss   
		        				      			INNER JOIN	Manufactory.[Sample] s
		        				      				ON	s.sample_id = tss.sample_id   
		        				      			INNER JOIN	Manufactory.TaskSample ts2
		        				      				ON	ts2.task_sample_id = s.task_sample_id
		        				      	WHERE	tss.ts_id = ts.ts_id
		        				      	ORDER BY
		        				      		CASE 
		        				      		     WHEN s.st_id = @st_priority THEN 0
		        				      		     ELSE 1
		        				      		END,
		        				      		s.task_sample_id
		        				      ) oa
		        		WHERE	ts.sew_employee_id IS NULL
		        				AND	ts.is_deleted = 0
		        				AND	ts.office_id = @office_id
		        				AND	ts.ct_id = @ct_id
		        				AND	NOT EXISTS(
		        				   		SELECT	1
		        				   		FROM	Manufactory.TaskSew ts2
		        				   		WHERE	ts2.sew_employee_id = @employee_id
		        				   				AND	ts2.sew_end_work_dt IS NULL
		        				   				AND	ts2.is_deleted = 0
		        				   	)
		        				AND	(ts.priority_employee_id IS NULL OR ts.priority_employee_id = @employee_id OR DATEDIFF(hour, ts.create_dt, @dt) > 24)
		        		ORDER BY
		        			CASE 
		        			     WHEN ts.priority_employee_id = @employee_id THEN 0
		        			     ELSE 1
		        			END ASC,
		        			oa.proirity_level DESC,
		        			oa.tp,
		        			oa.qp_id ASC,
		        			oa.task_sample_id ASC
		        	) vt
		END 	
		
		SELECT	ts.ts_id,
				s.sample_id,
				ct.ct_name,
				s.sketch_id,
				st.st_name,
				tsz.ts_name,
				ISNULL(sk.pattern_name, sk.sa_local) sa,
				an.art_name,
				sj.subject_name_sf subject_name,
				ts.employee_id        technolog_employee_id,
				s.comment,
				ts.comment            job_comment,
				s.employee_id,
				ts.estimated_time,
				est.employee_name     technology_employee_name,
				esc.employee_name     constructor_employee_name,
				b.brand_name
		FROM	Manufactory.TaskSew ts   
				INNER JOIN	Manufactory.TaskSewSample tss
					ON	tss.ts_id = ts.ts_id   
				INNER JOIN	Manufactory.[Sample] s
					ON	s.sample_id = tss.sample_id   
				INNER JOIN	Manufactory.SampleType st
					ON	st.st_id = s.st_id   
				LEFT JOIN	Products.TechSize tsz
					ON	tsz.ts_id = s.ts_id   
				INNER JOIN	Products.Sketch sk
					ON	sk.sketch_id = s.sketch_id 
				INNER JOIN Products.Brand b
					ON b.brand_id = sk.brand_id  
				INNER JOIN	Products.ArtName an
					ON	an.art_name_id = sk.art_name_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = sk.subject_id   
				INNER JOIN	Material.ClothType ct
					ON	ct.ct_id = s.ct_id   
				LEFT JOIN	Settings.EmployeeSetting est
					ON	sk.technology_employee_id = est.employee_id   
				LEFT JOIN	Settings.EmployeeSetting esc
					ON	sk.constructor_employee_id = esc.employee_id
		WHERE	ts.ts_id = @ts_id
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