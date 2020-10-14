CREATE PROCEDURE [Planing].[SketchPlan_AddIsPrePlan]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ps_id INT = 2 --Утвержден для подбора материалов
	DECLARE @qp_id TINYINT = 2
	DECLARE @spps_id TINYINT = 2 --Перенесен в план запуска
	DECLARE @proc_id INT
	DECLARE @status_rejected TINYINT = 3

	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @data_tab TABLE(spp_id INT PRIMARY KEY CLUSTERED)
	DECLARE @sketch_plan_output TABLE(sp_id INT, sketch_id INT, spp_id INT)
	
	DECLARE @sp_out TABLE (sp_id INT PRIMARY KEY CLUSTERED, sew_office_id INT, plan_sew_dt DATE)
	
	INSERT INTO @data_tab
		(
			spp_id
		)
	SELECT	ml.value('@spp[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = 'Не найдены следующие коды строчек предвартительного плана:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spp_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPrePlan spp
	      					ON	spp.spp_id = dt.spp_id
	      		WHERE	dt.spp_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = 'Ошибки:' + CHAR(10)
	      	+ (
	      		SELECT	CASE 
	      		      	     --WHEN s.technology_dt IS NULL THEN 'Не описана технология: ' + sj.subject_name + ' ' + an.art_name + ' (' +
	      		      	     --     s.sa + ')' + CHAR(10)
	      		      	     WHEN spp.plan_dt IS NULL THEN 'Не установлена плановая дата сдачи: ' + sj.subject_name + ' ' + an.art_name + ' (' +
	      		      	          s.sa + ')' + CHAR(10)
	      		      	     WHEN spp.sew_office_id IS NULL THEN 'Не указан офис отшива: ' + sj.subject_name + ' ' + an.art_name + ' (' +
	      		      	          s.sa + ')' + CHAR(10)
	      		      	     WHEN ISNULL(spp.plan_qty, 0) = 0 THEN 'Не указано количество на следующие позиции: ' + sj.subject_name + ' ' + an.art_name + ' (' +
	      		      	          s.sa + ')' + CHAR(10)
	      		      	     WHEN oa.ts_id IS NULL THEN 'Не удалось определить код ТНВД: ' + sj.subject_name + ' ' + an.art_name + ' (' +
	      		      	          s.sa + ')' + CHAR(10)
	      		      	     ELSE ''
	      		      	END
	      		FROM	@data_tab dt   
	      				INNER JOIN	Planing.SketchPrePlan spp
	      					ON	spp.spp_id = dt.spp_id   
	      				INNER JOIN	Products.Sketch s
	      					ON	s.sketch_id = spp.sketch_id   
	      				INNER JOIN	Products.ArtName an
	      					ON	an.art_name_id = s.art_name_id   
	      				INNER JOIN	Products.[Subject] sj
	      					ON	sj.subject_id = s.subject_id
	      				OUTER APPLY (
	      				      	SELECT	TOP(1) ts.ts_id
	      				      	FROM	Products.TNVED_Settigs ts
	      				      	WHERE	ts.subject_id = s.subject_id
	      				      			AND	ts.ct_id = s.ct_id
	      				      ) oa
	      		WHERE	ISNULL(spp.plan_qty, 0) = 0
	      				--OR	s.technology_dt IS NULL
	      				OR	spp.sew_office_id IS NULL
	      				OR	spp.plan_dt IS NULL
	      		ORDER BY
	      			CASE 
	      			     WHEN s.technology_dt IS NULL THEN 4
	      			     WHEN spp.plan_dt IS NULL THEN 3
	      			     WHEN spp.sew_office_id IS NULL THEN 2
	      			     WHEN ISNULL(spp.plan_qty, 0) = 0 THEN 1
	      			END
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	sp
		SET 	plan_sew_dt = spp.plan_dt,
				plan_month = MONTH(DATEADD(DAY, -60, spp.plan_dt)),
				plan_year = YEAR(DATEADD(DAY, -60, spp.plan_dt)),
				sew_office_id = spp.sew_office_id,
				plan_qty = spp.plan_qty,
				cv_qty = spp.cv_qty,
				ps_id = CASE 
				           WHEN sp.ps_id = @status_rejected THEN @ps_id
				           ELSE sp.ps_id
				      END
				OUTPUT INSERTED.sp_id, INSERTED.sew_office_id, INSERTED.plan_sew_dt INTO @sp_out(sp_id,
				                                                   sew_office_id, plan_sew_dt)
		FROM	Planing.SketchPlan sp
				INNER JOIN	Planing.SketchPrePlan spp
					ON	spp.spp_id = sp.spp_id
				INNER JOIN	@data_tab dt
					ON	dt.spp_id = spp.spp_id
		
		UPDATE	spcv
		SET 	sew_office_id = so.sew_office_id
				--,deadline_package_dt = DATEADD(DAY, -7, so.plan_sew_dt)
			OUTPUT	INSERTED.spcv_id,
						INSERTED.sp_id,
						INSERTED.spcv_name,
						INSERTED.cvs_id,
						INSERTED.qty,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.is_deleted,
						INSERTED.comment,
						INSERTED.pan_id,
						INSERTED.corrected_qty,
						INSERTED.begin_plan_delivery_dt,
						INSERTED.end_plan_delivery_dt,
						INSERTED.sew_office_id,
						INSERTED.sew_deadline_dt,
						INSERTED.cost_plan_year,
						INSERTED.cost_plan_month,
						@proc_id
				INTO	History.SketchPlanColorVariant (
						spcv_id,
						sp_id,
						spcv_name,
						cvs_id,
						qty,
						employee_id,
						dt,
						is_deleted,
						comment,
						pan_id,
						corrected_qty,
						begin_plan_delivery_dt,
						end_plan_delivery_dt,
						sew_office_id,
						sew_deadline_dt,
						cost_plan_year,
						cost_plan_month,
						proc_id
					)
		FROM	Planing.SketchPlanColorVariant spcv
				INNER JOIN	@sp_out so
					ON	so.sp_id = spcv.sp_id
		
		INSERT INTO Planing.SketchPlan
			(
				sketch_id,
				ps_id,
				create_employee_id,
				create_dt,
				employee_id,
				dt,
				comment,
				plan_year,
				plan_month,
				qp_id,
				plan_qty,
				cv_qty,
				plan_sew_dt,
				spp_id,
				sew_office_id,
				season_local_id,
				season_model_year
			)OUTPUT	INSERTED.sp_id,
			 		INSERTED.sketch_id,
			 		INSERTED.spp_id
			 INTO	@sketch_plan_output (
			 		sp_id,
			 		sketch_id,
			 		spp_id
			 	)
		SELECT	spp.sketch_id              sketch_id,
				@ps_id                     ps_id,
				spp.create_employee_id     create_employee_id,
				@dt                        create_dt,
				@employee_id               employee_id,
				@dt                        dt,
				NULL                       comment,
				YEAR(DATEADD(DAY, -60, spp.plan_dt))		  plan_year,
				MONTH(DATEADD(DAY, -60, spp.plan_dt))         plan_month,
				@qp_id                     qp_id,
				spp.plan_qty               plan_qty,
				spp.cv_qty                 cv_qty,
				spp.plan_dt                plan_sew_dt,
				spp.spp_id                 spp_id,
				spp.sew_office_id,
				spp.season_local_id,
				spp.season_model_year
		FROM	@data_tab dt   
				INNER JOIN	Planing.SketchPrePlan spp
					ON	spp.spp_id = dt.spp_id
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Planing.SketchPlan sp
		     		WHERE	sp.spp_id = spp.spp_id
		     	)
		
		INSERT INTO History.SketchPlan
			(
				sp_id,
				sketch_id,
				ps_id,
				employee_id,
				dt,
				comment
			)
		SELECT	spo.sp_id,
				spo.sketch_id,
				@ps_id,
				@employee_id,
				@dt,
				NULL
		FROM	@sketch_plan_output spo
		
		UPDATE	spp
		SET 	spp.spps_id = @spps_id,
				spp.employee_id = @employee_id,
				spp.dt = @dt
		FROM	Planing.SketchPrePlan spp
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	@sketch_plan_output spo
		     		WHERE	spo.spp_id = spp.spp_id
		     	) 
		
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