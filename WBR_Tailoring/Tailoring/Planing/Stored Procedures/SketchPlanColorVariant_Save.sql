
CREATE PROCEDURE [Planing].[SketchPlanColorVariant_Save]
	@sp_id INT,
	@employee_id INT,
	@xml_data XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cv_state_add TINYINT = 1
	DECLARE @cvc_state_need_proc TINYINT = 1
	DECLARE @proc_id INT
	DECLARE @sew_office_id INT
	DECLARE @deadline_package_dt DATE
	DECLARE @cost_plan_year SMALLINT
	DECLARE @cost_plan_month TINYINT
	DECLARE @sew_fabricator_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @var_tab TABLE(rn INT, spcv_id INT, spcv_name VARCHAR(36), qty SMALLINT, comment VARCHAR(300) NULL, completing XML, PRIMARY KEY CLUSTERED(rn))
	DECLARE @spcv_output_tab TABLE(
	        	rn INT NULL,
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
	
	DECLARE @var_compl_tab TABLE(
	        	rn INT NOT NULL,
	        	completing_id INT,
	        	completing_number TINYINT NOT NULL,
	        	rmt_id INT,
	        	color_id INT,
	        	frame_width SMALLINT,
	        	okei_id INT,
	        	consumption DECIMAL(9, 3),
	        	comment VARCHAR(300),
	        	supplier_id INT,
	        	PRIMARY KEY CLUSTERED(rn, completing_id, completing_number)
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN sp.sp_id IS NULL THEN 'Строчки плана с номером ' + CAST(v.sp_id AS VARCHAR(10)) + ' не существует'
	      	                   ELSE NULL
	      	              END,
			@sew_office_id           = sp.sew_office_id,
			@sew_fabricator_id		 = sp.sew_fabricator_id,
			@deadline_package_dt     =
			CASE 
			     WHEN sp.spp_id IS NULL THEN NULL
			     ELSE DATEADD(DAY, -7, sp.plan_sew_dt)
			END,
			@cost_plan_year = CASE 
									 WHEN sp.season_local_id = 6 THEN YEAR(@dt)
									 ELSE NULL
								END,
			@cost_plan_month = CASE 
									 WHEN sp.season_local_id = 6 THEN MONTH(@dt)
									 ELSE NULL
								END
			
	FROM	(VALUES(@sp_id))v(sp_id)   
			LEFT JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = v.sp_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_spcv
			      	FROM	Planing.SketchPlanColorVariant spcv
			      	WHERE	spcv.sp_id = spcv.sp_id
			      ) oa
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @var_tab
		(
			rn,
			spcv_id,
			spcv_name,
			qty,
			comment,
			completing
		)
	SELECT	ROW_NUMBER() OVER(ORDER BY ml.value('@id', 'int')) rn,
			ml.value('@id', 'int')           spcv_id,
			ml.value('@name', 'varchar(36)') spcv_name,
			ml.value('@qty', 'smallint')     qty,
			ml.value('@com', 'varchar(300)') comment,
			ml.query('comgs')                completing
	FROM	@xml_data.nodes('variants/variant')x(ml)	
	
	INSERT INTO @var_compl_tab
		(
			rn,
			completing_id,
			completing_number,
			rmt_id,
			color_id,
			frame_width,
			okei_id,
			consumption,
			comment,
			supplier_id
		)
	SELECT	vt.rn                           rn,
			ml.value('@cid', 'int')         completing_id,
			ml.value('@num', 'tinyint')     completing_number,
			ml.value('@rmid', 'int')        rmt_id,
			ml.value('@color', 'int')       color_id,
			ml.value('@fw', 'smallint')     frame_width,
			ml.value('@okei', 'int')        okei_id,
			ml.value('@cm', 'decimal(9,3)') consumption,
			ml.value('@com', 'varchar(300)') comment,
			ml.value('@sup', 'int')			supplier_id
	FROM	@var_tab vt   
			CROSS APPLY vt.completing.nodes('comgs/comg')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN oa_cnt.cnt > 1 THEN 'Наименование цветоварианта ' + vt.spcv_name + ' повторяется более одного раза.'
	      	                   WHEN ISNULL(vt.qty, 0) <= 0 THEN 'Для цветоварианта ' + vt.spcv_name + ' указано неверное количество ' + CAST(vt.qty AS VARCHAR(10)) 
	      	                        + '.'
	      	                   ELSE NULL
	      	              END
	FROM	@var_tab vt   
			OUTER APPLY (
			      	SELECT	COUNT(1)     cnt
			      	FROM	@var_tab     vt2
			      	WHERE	vt2.spcv_name = vt.spcv_name
			      ) oa_cnt
	WHERE	oa_cnt.cnt > 1
			OR	vt.qty <= 0 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		      
	
	SELECT	@error_text = CASE 
	      	                   WHEN vct.rn IS NULL THEN 'Для цветоварианта ' + vt.spcv_name + ' не указанв комплектация.'
	      	                   WHEN c.completing_id IS NULL THEN 'Комплектации с кодом ' + CAST(vct.completing_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(vct.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN o.okei_id IS NULL THEN 'Еденицы измерения с кодом ' + CAST(vct.okei_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN vct.color_id IS NULL THEN 'Для цветоварианта ' + vt.spcv_name + ' | ' + c.completing_name + ' номер комплектации ' + CAST(vct.completing_number AS VARCHAR(10)) 
	      	                        + ' не указан цвет.'
	      	                   WHEN cc.color_id IS NULL THEN 'Цвета с кодом ' + CAST(vct.color_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN oa_cn_cnt.cnt > 1 THEN 'Для цветоварианта ' + vt.spcv_name + ' | ' + c.completing_name + ' номер комплектации ' + CAST(vct.completing_number AS VARCHAR(10)) 
	      	                        + ' указан более одного раза.'
	      	                   WHEN oa_p.is_parent IS NOT NULL THEN 'Тип материяла ' + rmt.rmt_name +
	      	                        ' не является конечным элементом справочника. Использовать нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	@var_tab vt   
			LEFT JOIN	@var_compl_tab vct
				ON	vct.rn = vt.rn   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = vct.completing_id   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = vct.rmt_id   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = vct.okei_id   
			LEFT JOIN	Material.ClothColor cc
				ON	cc.color_id = vct.color_id   
			OUTER APPLY (
			      	SELECT	COUNT(1) cnt
			      	FROM	@var_compl_tab vct2
			      	WHERE	vct2.rn = vct.rn
			      			AND	vct2.completing_id = vct.completing_id
			      			AND	vct2.completing_number = vct.completing_number
			      ) oa_cn_cnt
	OUTER APPLY (
	      	SELECT	TOP(1) 1 is_parent
	      	FROM	Material.RawMaterialType rmt2
	      	WHERE	rmt2.rmt_pid = rmt.rmt_id
	      ) oa_p
	WHERE	vct.rn IS NULL
			OR	c.completing_id IS NULL
			OR	rmt.rmt_id IS NULL
			OR	o.okei_id IS NULL
			OR	vct.color_id IS NULL
			OR	cc.color_id IS NULL
			OR	oa_cn_cnt.cnt > 1
			OR	oa_p.is_parent IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.is_deleted = 0 AND spcv.cvs_id != 1 AND vt.spcv_id IS NULL THEN 'Цветоварианта ' + spcv.spcv_name + ' имеет статус ' +
	      	                        cvs.cvs_name + ' , удалять нельзя.'
	      	                   WHEN spcv.is_deleted = 0 AND vt.spcv_id IS NULL AND oar.is_reserv IS NOT NULL THEN 'Цветоварианта ' + spcv.spcv_name + 
	      	                        ' имеет резерв , удалять нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id   
			LEFT JOIN	@var_tab vt
				ON	vt.spcv_id = spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_reserv
			      	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			      			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
			      				ON	smr.spcvc_id = spcvc.spcvc_id
			      	WHERE	spcvc.spcv_id = spcv.spcv_id
			      ) oar
	WHERE	spcv.sp_id = @sp_id
			AND	spcv.is_deleted = 0
			AND	(spcv.cvs_id != 1 OR oar.is_reserv IS NOT NULL)
			AND	vt.spcv_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		;
		WITH cte_Target AS (
			SELECT	spcv.spcv_id,
					spcv.sp_id,
					spcv.spcv_name,
					spcv.cvs_id,
					spcv.qty,
					spcv.employee_id,
					spcv.dt,
					spcv.is_deleted,
					spcv.comment,
					spcv.pan_id,
					spcv.corrected_qty,
					spcv.begin_plan_delivery_dt,
					spcv.end_plan_delivery_dt,
					spcv.sew_office_id,
					spcv.sew_deadline_dt,
					spcv.cost_plan_year,
					spcv.cost_plan_month,
					spcv.deadline_package_dt,
					spcv.sew_fabricator_id
			FROM	Planing.SketchPlanColorVariant spcv
			WHERE	spcv.sp_id = @sp_id
		)
		MERGE cte_Target t
		USING @var_tab s
				ON s.spcv_id = t.spcv_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	spcv_name               = s.spcv_name,
		     		qty                     = s.qty,
		     		employee_id             = @employee_id,
		     		dt                      = @dt,
		     		is_deleted              = 0,
		     		comment                 = s.comment,
		     		sew_office_id           = ISNULL(t.sew_office_id, @sew_office_id),
					sew_fabricator_id		= ISNULL(t.sew_office_id, @sew_fabricator_id)
		     		--,deadline_package_dt     = @deadline_package_dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		sp_id,
		     		spcv_name,
		     		cvs_id,
		     		qty,
		     		employee_id,
		     		dt,
		     		is_deleted,
		     		comment,
		     		sew_office_id,
		     		deadline_package_dt,
		     		cost_plan_year,
					cost_plan_month,
					sew_fabricator_id
		     	)
		     VALUES
		     	(
		     		@sp_id,
		     		s.spcv_name,
		     		@cv_state_add,
		     		s.qty,
		     		@employee_id,
		     		@dt,
		     		0,
		     		s.comment,
		     		@sew_office_id,
		     		NULL,
		     		@cost_plan_year,
		     		@cost_plan_month,
					@sew_fabricator_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     UPDATE	
		     SET 	employee_id     = @employee_id,
		     		dt              = @dt,
		     		is_deleted      = 1
		     		OUTPUT	s.rn,
		     				INSERTED.spcv_id,
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
		     				rn,
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
		     			);
		
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
				sot.sew_fabricator_id
		FROM	@spcv_output_tab sot
		
		;
		DELETE	spcvcc
		FROM	Planing.SketchPlanColorVariantCompletingComment spcvcc   
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = spcvcc.spcvc_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvc.spcv_id
		WHERE	spcv.sp_id = @sp_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	@spcv_output_tab ot   
				   				INNER JOIN	@var_compl_tab vct
				   					ON	vct.rn = ot.rn
				   		WHERE	ot.spcv_id = spcvc.spcv_id
				   				AND	vct.completing_id = spcvc.completing_id
				   				AND	vct.completing_number = spcvc.completing_number
				   	) ;
				
		DELETE	pcr
		FROM	Planing.PreCostReserv pcr   
				INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
					ON	spcvc.spcvc_id = pcr.spcvc_id   
				INNER JOIN	Planing.SketchPlanColorVariant spcv
					ON	spcv.spcv_id = spcvc.spcv_id   
				INNER JOIN	@spcv_output_tab sot
					ON	sot.spcv_id = spcvc.spcv_id   
				LEFT JOIN	@var_compl_tab vct
					ON	vct.rn = sot.rn
					AND	vct.completing_id = spcvc.completing_id
					AND	vct.completing_number = spcvc.completing_number
		WHERE	sot.rn IS NOT NULL
				AND	vct.rn IS NULL
				AND	spcv.sp_id = @sp_id
		
		;
		WITH cte_Target AS (
			SELECT	spcvc.spcvc_id,
					spcvc.spcv_id,
					spcvc.completing_id,
					spcvc.completing_number,
					spcvc.rmt_id,
					spcvc.color_id,
					spcvc.frame_width,
					spcvc.okei_id,
					spcvc.consumption,
					spcvc.comment,
					spcvc.dt,
					spcvc.employee_id,
					spcvc.cs_id,
					spcvc.supplier_id
			FROM	Planing.SketchPlanColorVariantCompleting spcvc
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@spcv_output_tab sot
			     		WHERE	sot.spcv_id = spcvc.spcv_id
			     				AND	sot.rn IS NOT NULL
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	ot.spcv_id,
		      			vct.completing_id,
		      			vct.completing_number,
		      			vct.rmt_id,
		      			vct.color_id,
		      			vct.frame_width,
		      			vct.okei_id,
		      			vct.consumption,
		      			vct.comment,
		      			vct.supplier_id
		      	FROM	@spcv_output_tab ot   
		      			INNER JOIN	@var_compl_tab vct
		      				ON	vct.rn = ot.rn
		      ) s
				ON t.spcv_id = s.spcv_id
				AND t.completing_id = s.completing_id
				AND t.completing_number = s.completing_number
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	rmt_id          = s.rmt_id,
		     		color_id        = s.color_id,
		     		frame_width     = s.frame_width,
		     		okei_id         = s.okei_id,
		     		consumption     = s.consumption,
		     		comment         = s.comment,
		     		dt              = @dt,
		     		employee_id     = @employee_id,
		     		supplier_id		= s.supplier_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		spcv_id,
		     		completing_id,
		     		completing_number,
		     		rmt_id,
		     		color_id,
		     		frame_width,
		     		okei_id,
		     		consumption,
		     		comment,
		     		dt,
		     		employee_id,
		     		cs_id,
		     		supplier_id
		     	)
		     VALUES
		     	(
		     		s.spcv_id,
		     		s.completing_id,
		     		s.completing_number,
		     		s.rmt_id,
		     		s.color_id,
		     		s.frame_width,
		     		s.okei_id,
		     		s.consumption,
		     		s.comment,
		     		@dt,
		     		@employee_id,
		     		@cvc_state_need_proc,
		     		supplier_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	OUTPUT	ISNULL(INSERTED.spcvc_id, DELETED.spcvc_id),
		           			ISNULL(INSERTED.spcv_id, DELETED.spcv_id),
		           			ISNULL(INSERTED.completing_id, DELETED.completing_id),
		           			ISNULL(INSERTED.completing_number, DELETED.completing_number),
		           			ISNULL(INSERTED.rmt_id, DELETED.rmt_id),
		           			ISNULL(INSERTED.color_id, DELETED.color_id),
		           			ISNULL(INSERTED.frame_width, DELETED.frame_width),
		           			ISNULL(INSERTED.okei_id, DELETED.okei_id),
		           			ISNULL(INSERTED.consumption, DELETED.consumption),
		           			ISNULL(INSERTED.comment, 'DEL'),
		           			ISNULL(INSERTED.dt, @dt),
		           			ISNULL(INSERTED.employee_id, @employee_id),
		           			ISNULL(INSERTED.cs_id, DELETED.cs_id),
		           			@proc_id
		           	INTO	History.SketchPlanColorVariantCompleting (
		           			spcvc_id,
		           			spcv_id,
		           			completing_id,
		           			completing_number,
		           			rmt_id,
		           			color_id,
		           			frame_width,
		           			okei_id,
		           			consumption,
		           			comment,
		           			dt,
		           			employee_id,
		           			cs_id,
		           			proc_id
		           		); 
		
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
	END CATCH 