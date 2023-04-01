
CREATE PROCEDURE [Planing].[SketchPlanColorVariant_AddForBranding]
	@pan_id INT,
	@data_xml XML,
	@employee_id INT,
	@fabricator_id INT

AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @ts_tab TABLE (ts_id INT, cnt SMALLINT)
	DECLARE @sketch_id INT
	DECLARE @ps_id SMALLINT = 4
	DECLARE @qp_id SMALLINT = 2
	DECLARE @season_local_id INT = 7
	DECLARE @cvs_id INT = 15
	DECLARE @qty SMALLINT
	DECLARE @proc_id INT
	DECLARE @pt_id INT
	DECLARE @sketch_plan_output TABLE(sp_id INT, sketch_id INT)
	DECLARE @spcv_output_tab TABLE(
	        	spcv_id INT NOT NULL,
	        	sp_id INT NOT NULL,
	        	spcv_name VARCHAR(36) NOT NULL,
	        	cvs_id TINYINT NOT NULL,
	        	qty SMALLINT NOT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	comment VARCHAR(300) NULL,
	        	pan_id INT NULL,
	        	corrected_qty SMALLINT NULL,
	        	begin_plan_delivery_dt DATE NULL,
	        	end_plan_delivery_dt DATE NULL,
	        	sew_office_id INT NULL,
	        	sew_deadline_dt DATE NULL,
	        	cost_plan_year SMALLINT NULL,
	        	cost_plan_month TINYINT NULL,
				sew_fabricator_id INT NULL
	        )
	
	DECLARE @spcvts_out TABLE (spcvts_id INT, ts_id INT, qty SMALLINT)
	DECLARE @cutting_out TABLE (cutting_id INT, qty SMALLINT)
	DECLARE @covering_out     TABLE (covering_id INT)
	DECLARE @office_id        INT = (
	        	SELECT	os.office_id
	        	FROM	Settings.OfficeSetting os
	        	WHERE	os.is_main_wh = 1
	        )

	
	IF @office_id IS NULL
	BEGIN
	    RAISERROR('Не удалось вычислить офис по умолчанию', 16, 1)
	    RETURN
	END              
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN pan.pan_id IS NULL THEN 'Цветоартикула с кодом pan_id ' + CAST(v.pan_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN pan.pan_id IS NOT NULL AND s.pt_id IS NULL THEN 'Не указан тип продукта'
	      	                   ELSE NULL
	      	              END,
			@sketch_id = pa.sketch_id,
			@pt_id = s.pt_id
	FROM	(VALUES(@pan_id))v(pan_id)   
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = v.pan_id   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	INSERT INTO @ts_tab
		(
			ts_id,
			cnt
		)
	SELECT	ml.value('@id', 'int'),
			ml.value('@cnt', 'smallint')
	FROM	@data_xml.nodes('root/ts')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ts.ts_id IS NULL THEN 'Размера с кодом ' + CAST(tt.ts_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN pants.ts_id IS NULL THEN 'Размера ' + ts.ts_name + ' нет у артикула сайта.'
	      	                   ELSE NULL
	      	              END
	FROM	@ts_tab tt   
			LEFT JOIN	Products.TechSize ts
				ON	ts.ts_id = tt.ts_id   
			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.ts_id = ts.ts_id
				AND	pants.pan_id = @pan_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	SELECT	@qty = SUM(tt.cnt)
	FROM	@ts_tab tt
	
	IF ISNULL(@qty, 0) = 0
	BEGIN
	    RAISERROR('Общее количество должно быть больше 0', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Synchro.ProductsForEAN
			(
				pants_id,
				fabricator_id
			)
		SELECT	pants.pants_id,f.fabricator_id
		FROM	Products.ProdArticleNomenclatureTechSize pants   
				LEFT JOIN	Synchro.ProductsForEAN pfe
					ON	pfe.pants_id = pants.pants_id
				CROSS JOIN Settings.Fabricators f
		WHERE	pants.pan_id = @pan_id
				AND	pfe.pants_id IS NULL
		
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
				season_local_id,
				sew_office_id,
				sew_fabricator_id
			)OUTPUT	INSERTED.sp_id,
			 		INSERTED.sketch_id
			 INTO	@sketch_plan_output (
			 		sp_id,
			 		sketch_id
			 	)
		VALUES
			(
				@sketch_id,
				@ps_id,
				@employee_id,
				@dt,
				@employee_id,
				@dt,
				'Создан для брендирования',
				YEAR(@dt),
				MONTH(@dt),
				@qp_id,
				@qty,
				@qty,
				@dt,
				@season_local_id,
				NULL,
				@fabricator_id
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
		
		INSERT INTO Planing.SketchPlanColorVariant
			(
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
				cost_plan_year,
				cost_plan_month,
				sew_fabricator_id
			)OUTPUT	INSERTED.spcv_id,
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
					INSERTED.sew_fabricator_id
			 INTO	@spcv_output_tab (
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
					sew_fabricator_id
			 	)
		SELECT	spo.sp_id,
				'Брендирование',
				@cvs_id,
				@qty,
				@employee_id,
				@dt,
				0,
				'Создан для брендирования',
				@pan_id,
				@qty,
				YEAR(@dt),
				MONTH(@dt),
				@fabricator_id
		FROM	@sketch_plan_output spo
		
		INSERT INTO History.SketchPlanColorVariant
			(
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
				proc_id,
				sew_fabricator_id
			)
		SELECT	sot.spcv_id,
				sot.sp_id,
				sot.spcv_name,
				sot.cvs_id,
				sot.qty,
				sot.employee_id,
				sot.dt,
				sot.is_deleted,
				sot.comment,
				sot.pan_id,
				sot.corrected_qty,
				sot.begin_plan_delivery_dt,
				sot.end_plan_delivery_dt,
				sot.sew_office_id,
				sot.sew_deadline_dt,
				sot.cost_plan_year,
				sot.cost_plan_month,
				@proc_id,
				@fabricator_id
		FROM	@spcv_output_tab sot
		
		INSERT INTO Planing.SketchPlanColorVariantTS
			(
				spcv_id,
				ts_id,
				cnt,
				dt,
				employee_id
			)OUTPUT	INSERTED.spcvts_id,
			 		INSERTED.ts_id,
			 		INSERTED.cnt
			 INTO	@spcvts_out (
			 		spcvts_id,
			 		ts_id,
			 		qty
			 	)
		SELECT	sot.spcv_id,
				tt.ts_id,
				tt.cnt,
				@dt,
				@employee_id
		FROM	@spcv_output_tab sot   
				CROSS JOIN	@ts_tab tt
		
		INSERT INTO Planing.SketchPlanColorVariantTSCounter
			(
				spcvts_id,
				cutting_qty,
				cut_write_off,
				write_off,
				packaging,
				finished
			)
		SELECT	so.spcvts_id,
				so.qty,
				0,
				0,
				0,
				0
		FROM	@spcvts_out so
		
		INSERT INTO Manufactory.Cutting
			(
				office_id,
				plan_year,
				plan_month, 
				pants_id,
				plan_count,
				create_employee_id,
				create_dt,
				employee_id,
				dt,
				perimeter,
				pt_id,
				plan_start_dt,
				spcvts_id,
				cutting_tariff
			)OUTPUT	INSERTED.cutting_id,
			 		INSERTED.plan_count
			 INTO	@cutting_out (
			 		cutting_id,
			 		qty
			 	)
		SELECT	@office_id       office_id,
				YEAR(@dt)        plan_year,
				MONTH(@dt)       plan_month,
				pants.pants_id,
				so.qty           plan_count,
				@employee_id     employee_id,
				@dt              dt,
				@employee_id     employee_id,
				@dt              dt,
				0                perimeter,
				@pt_id           pt_id,
				@dt              plan_start_dt,
				so.spcvts_id     spcvts_id,
				0                cutting_tariff
		FROM	@spcvts_out so   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.ts_id = so.ts_id
					AND	pants.pan_id = @pan_id 
		
		INSERT INTO Manufactory.CuttingActual
			(
				cutting_id,
				actual_count,
				dt,
				employee_id
			)
		SELECT	co.cutting_id,
				co.qty,
				@dt,
				@employee_id
		FROM	@cutting_out co
		
		INSERT INTO Planing.Covering
			(
				create_dt,
				create_employee_id,
				office_id,
				close_dt,
				close_employee_id,
				cost_dt,
				cost_employee_id,
				cutting_dt
			)OUTPUT	INSERTED.covering_id
			 INTO	@covering_out (
			 		covering_id
			 	)
		VALUES
			(
				@dt,
				@employee_id,
				@office_id,
				@dt,
				@employee_id,
				NULL,
				NULL,
				@dt
			)
		
		INSERT INTO Planing.CoveringDetail
			(
				covering_id,
				spcv_id,
				dt,
				employee_id,
				is_deleted
			)
		SELECT	co.covering_id,
				sot.spcv_id,
				@dt,
				@employee_id,
				0
		FROM	@covering_out co   
				CROSS JOIN	@spcv_output_tab sot
		
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
		--WITH LOG;
	END CATCH 