CREATE PROCEDURE [Planing].[Covering_AddIn]
	@spcv_xml XML,
	@empl_xml XML,
	@employee_id INT,
	@covering_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_tab TABLE (spcv_id INT, is_added BIT)
	DECLARE @employee_tab TABLE (employee_id INT PRIMARY KEY CLUSTERED)
	DECLARE @cv_status_placing TINYINT = 12 --Назначен в цех
	DECLARE @cv_status_rm_issue TINYINT = 14 --На выдаче материалов
	DECLARE @office_id INT
	DECLARE @covering_reserv TABLE (spcv_id INT, spcvc_id INT, shkrm_id INT, okei_id INT, quantity DECIMAL(9, 3), pre_cost DECIMAL(9, 2))
	
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' уже закрыта.'	      	                   
	      	                   ELSE NULL
	      	              END,
	      	              @office_id = c.office_id
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id   
			
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			is_added
		)
	SELECT	ml.value('@spcv', 'int'),
			0
	FROM	@spcv_xml.nodes('root/det')x(ml)
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			is_added
		)
	SELECT	aspm.linked_spcv_id,
			1
	FROM	Planing.AddedSketchPlanMapping aspm   
			INNER JOIN	@spcv_tab st
				ON	aspm.base_spcv_id = st.spcv_id
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spcv.cvs_id != @cv_status_placing THEN 'Статус цветоварианта ' + spcv.spcv_name + ' артикула ' + s.sa +
	      	                        ' не позволяет назначить его в выдачу.'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND spcv.pan_id IS NULL THEN 'Артикул ' + s.sa + ' не связан с кодом сайта'
	      	                   WHEN oa.cnt > 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' указан более одного раза'
	      	                   WHEN s.pt_id IS NULL THEN 'У артикула ' + s.sa + ' не указан тип продукта'
	      	                   WHEN spcv.sew_office_id != @office_id THEN 'Цветовариант ' + spcv.spcv_name + ' артикула ' + s.sa + ' назначен в другой офис'
	      	                   WHEN cd.covering_id IS NOT NULL THEN 'Цветовариант ' + spcv.spcv_name + ' артикула ' + s.sa + ' уже в выдаче № ' + CAST(cd.covering_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id
				ON	spcv.spcv_id = dt.spcv_id  
			LEFT JOIN Planing.CoveringDetail cd
				ON cd.spcv_id = spcv.spcv_id 
			OUTER APPLY (
			      	SELECT	COUNT(dt2.spcv_id) cnt
			      	FROM	@spcv_tab dt2
			      	WHERE	dt2.spcv_id = dt.spcv_id
			      ) oa
	WHERE	spcv.spcv_id IS NULL
			OR	spcv.cvs_id != @cv_status_placing
			OR	oa.cnt > 1
			OR	spcv.pan_id IS NULL
			OR	s.pt_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.spcvts_id IS NULL THEN 'Цветовариант ' + spcv.spcv_name + ' артикула ' + s.sa + ' нет в плане раскроя'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = dt.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = dt.spcv_id
				AND	spcvt.cnt > 0   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.spcvts_id = spcvt.spcvts_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @employee_tab
		(
			employee_id
		)
	SELECT	ml.value('@empl', 'int')
	FROM	@empl_xml.nodes('root/det')x(ml)
	
	INSERT INTO @covering_reserv
		(
			spcv_id,
			spcvc_id,
			shkrm_id,
			okei_id,
			quantity,
			pre_cost
		)
	SELECT	st.spcv_id,
			spcvc.spcvc_id,
			smr.shkrm_id,
			smr.okei_id,
			smr.quantity,
			COALESCE(sma0.amount / sma0.stor_unit_residues_qty,oa1.price, oa2.price, oa3.price, 0) * smr.quantity pre_cost
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = st.spcv_id   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id 
			LEFT JOIN Warehouse.SHKRawMaterialAmount sma0
				ON sma0.shkrm_id = smr.shkrm_id AND sma0.final_dt IS NOT NULL AND sma0.amount != 0   
			OUTER APPLY (
			      	SELECT	AVG(v.price) price
			      	FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
			      	    	 FROM	Warehouse.SHKRawMaterialAmount sma   
			      	    	 		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
			      	    	 			ON	smi.shkrm_id = sma.shkrm_id
			      	    	 WHERE	smi.rmt_id = smai.rmt_id
			      	    	 		AND	smi.art_id = smai.art_id
			      	    	 		AND	sma.final_dt IS NOT NULL
			      	    	 		AND	sma.amount != 0
			      	    	 ORDER BY
			      	    	 	sma.final_dt DESC)v
			      ) oa1
			OUTER APPLY (
	      			SELECT	AVG(v.price) price
	      			FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    			 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 				INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 					ON	smi.shkrm_id = sma.shkrm_id
	      	    			 WHERE	smi.rmt_id = smai.rmt_id
	      	    	 				AND	sma.final_dt IS NOT NULL
	      	    	 				AND	sma.amount != 0
	      	    			 ORDER BY
	      	    	 			sma.final_dt DESC)v
				  ) oa2
			OUTER APPLY (
	      			SELECT	AVG(v.price) price
	      			FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    			 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 				INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 					ON	smi.shkrm_id = sma.shkrm_id   
	      	    	 				INNER JOIN	Material.RawMaterialType rmt2
	      	    	 					ON	rmt2.rmt_id = smi.rmt_id
	      	    			 WHERE	rmt.rmt_pid = rmt2.rmt_pid
	      	    	 				AND	sma.final_dt IS NOT NULL
	      	    	 				AND	sma.amount != 0
	      	    			 ORDER BY
	      	    	 			sma.final_dt DESC)v
				  ) oa3
		
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	spcv
		SET 	employee_id = @employee_id,
				dt = @dt,
				cvs_id = @cv_status_rm_issue
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
				INNER JOIN	@spcv_tab dt
					ON	dt.spcv_id = spcv.spcv_id		
		
		UPDATE	c
		SET 	employee_id             = @employee_id,
				dt                      = @dt,
				planing_employee_id     = @employee_id,
				planing_dt              = @dt
		FROM	Manufactory.Cutting c
				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
					ON	spcvt.spcvts_id = c.spcvts_id
				INNER JOIN	@spcv_tab d
					ON	d.spcv_id = spcvt.spcv_id
		
		;
		WITH cte_Target AS
		(
			SELECT	ce.cutting_id,
					ce.employee_id
			FROM	Manufactory.CuttingEmployee ce
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	Manufactory.Cutting c   
			     				INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
			     					ON	spcvt.spcvts_id = c.spcvts_id   
			     				INNER JOIN	@spcv_tab d
			     					ON	d.spcv_id = spcvt.spcv_id
			     		WHERE	ce.cutting_id = c.cutting_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	c.cutting_id,
		      			et.employee_id
		      	FROM	Manufactory.Cutting c   
		      			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
		      				ON	spcvt.spcvts_id = c.spcvts_id   
		      			INNER JOIN	@spcv_tab d
		      				ON	d.spcv_id = spcvt.spcv_id   
		      			CROSS JOIN	@employee_tab et
		      ) s
				ON t.cutting_id = s.cutting_id
				AND t.employee_id = s.employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		cutting_id,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.cutting_id,
		     		s.employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		INSERT INTO Planing.CoveringDetail
			(
				covering_id,
				spcv_id,
				dt,
				employee_id,
				is_deleted
			)
		SELECT	@covering_id,
				st.spcv_id,
				@dt,
				@employee_id,
				0
		FROM	@spcv_tab st   
		
		INSERT INTO Planing.CoveringReserv
			(
				covering_id,
				spcvc_id,
				shkrm_id,
				okei_id,
				qty,
				dt,
				employee_id,
				pre_cost
			)
		SELECT	@covering_id,
				cr.spcvc_id,
				cr.shkrm_id,
				cr.okei_id,
				cr.quantity,
				@dt,
				@employee_id,
				cr.pre_cost
		FROM	@covering_reserv cr 
		
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
	