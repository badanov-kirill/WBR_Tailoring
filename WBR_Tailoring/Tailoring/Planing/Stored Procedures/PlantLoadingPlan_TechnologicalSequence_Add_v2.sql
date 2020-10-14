CREATE PROCEDURE [Planing].[PlantLoadingPlan_TechnologicalSequence_Add_v2]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_tab TABLE (spcv_id INT, sketch_id INT, ct_id INT, pt_id TINYINT, control_work_time INT, perimetr DECIMAL(15, 5), qty SMALLINT, max_operation INT, is_plp BIT)
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			sketch_id,
			ct_id,
			pt_id,
			control_work_time,
			perimetr,
			qty,
			max_operation,
			is_plp
		)
	SELECT	ml.value('@spcv', 'int'),
			sp.sketch_id,
			s.ct_id,
			s.pt_id,
			pt.work_time,
			oa.perimetr,
			ISNULL(spcv.corrected_qty, spcv.qty),
			oa_ts.max_operation,
			CASE 
			     WHEN plp.spcv_id IS NULL THEN 0
			     ELSE 1
			END
	FROM	@data_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			LEFT JOIN	Planing.PlantLoadingPlan plp
				ON	plp.spcv_id = spcv.spcv_id
				ON	ml.value('@spcv',
			'int')= spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	AVG(spp.perimetr) perimetr
			      	FROM	Products.SketchPatternPerimetr spp
			      	WHERE	spp.sketch_id = s.sketch_id
			      ) oa
	OUTER APPLY (
	      	SELECT	MAX(ts.operation_range) max_operation
	      	FROM	Products.TechnologicalSequence ts
	      	WHERE	ts.sketch_id = sp.sketch_id
	      ) oa_ts
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.sketch_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN dt.is_plp = 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) +
	      	                        ' уже в плане рассчета.'
	      	                   WHEN dt.sketch_id IS NOT NULL AND dt.pt_id IS NULL THEN 'У цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) +
	      	                        'не указан тип изделия'
	      	                   WHEN dt.sketch_id IS NOT NULL AND dt.ct_id IS NULL THEN 'У цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) +
	      	                        ' не указан ассортимент'
	      	                   WHEN dt.sketch_id IS NOT NULL AND ISNULL(dt.perimetr, 0) = 0 THEN 'У цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) +
	      	                        'не указаны периметры'
	      	                   WHEN dt.sketch_id IS NOT NULL AND ISNULL(dt.max_operation, 0) < 5 THEN 'У цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) 
	      	                        + ' не заполнена техпоследовательность'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt
	WHERE	dt.sketch_id IS NULL
			OR	dt.is_plp = 1
			OR	dt.pt_id IS NULL
			OR	dt.ct_id IS NULL
			OR	ISNULL(dt.perimetr, 0) = 0
			OR	ISNULL(dt.max_operation, 0) < 5
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	plptsw
		FROM	Planing.PlantLoadingPlan_TechnologicalSequenceWork plptsw   
				INNER JOIN	Planing.PlantLoadingPlan_TechnologicalSequence plpts
					ON	plpts.plpts_id = plptsw.plpts_id
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	@spcv_tab dt
		     		WHERE	dt.spcv_id = plpts.spcv_id
		     	)
		
		;WITH cte_Target AS
		(
			SELECT	plpts.spcv_id,
					plpts.operation_range,
					plpts.ct_id,
					plpts.ta_id,
					plpts.element_id,
					plpts.equipment_id,
					plpts.dr_id,
					plpts.dc_id,
					plpts.operation_value,
					plpts.discharge_id,
					plpts.rotaiting,
					plpts.dc_coefficient,
					plpts.employee_id,
					plpts.dt,
					plpts.operation_time,
					plpts.comment_id
			FROM	Planing.PlantLoadingPlan_TechnologicalSequence plpts
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@spcv_tab dt
			     		WHERE	dt.spcv_id = plpts.spcv_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	st.spcv_id spcv_id,
		      			ts.operation_range,
		      			ts.ct_id,
		      			ts.ta_id,
		      			ts.element_id,
		      			ts.equipment_id,
		      			ts.dr_id,
		      			ts.dc_id,
		      			ts.operation_value,
		      			ts.discharge_id,
		      			ts.rotaiting,
		      			ts.dc_coefficient,
		      			ts.employee_id,
		      			ts.dt,
		      			ts.comment_id
		      	FROM	@spcv_tab st   
		      			INNER JOIN	Products.TechnologicalSequence ts
		      				ON	ts.sketch_id = st.sketch_id
		      	UNION
		      	ALL
		      	SELECT	st.spcv_id     spcv_id,
		      			0                operation_range,
		      			st.ct_id         ct_id,
		      			108              ta_id,	--разрезать
		      			580              element_id,	--изделие
		      			26               equipment_id,	--Раскройный стол
		      			2                dr_id,	--средняя
		      			1                dc_id,	--Без совмещения рисунка
		      			1                operation_value,
		      			1                discharge_id,
		      			CAST(st.perimetr / 55 AS INT),
		      			1                dc_coefficient,
		      			@employee_id,
		      			@dt,
		      			2472
		      	FROM	@spcv_tab        st
		      	UNION
		      	ALL 
		      	SELECT	st.spcv_id,
		      			st.max_operation + 1 operation_range,
		      			st.ct_id      ct_id,
		      			99            ta_id,	--проверить
		      			580           element_id,	--изделие
		      			27            equipment_id,	--Стол контроля качества и упаковки
		      			2             dr_id,	--средняя
		      			1             dc_id,	--Без совмещения рисунка
		      			1             operation_value,
		      			1             discharge_id,
		      			st.control_work_time,
		      			1             dc_coefficient,
		      			@employee_id,
		      			@dt,
		      			2473
		      	FROM	@spcv_tab     st
		      ) s
				ON s.spcv_id = t.spcv_id
				AND s.operation_range = t.operation_range
		WHEN MATCHED AND (
		     	s.ct_id != t.ct_id
		     	OR s.ta_id != t.ta_id
		     	OR s.element_id != t.element_id
		     	OR s.equipment_id != t.equipment_id
		     	OR s.dr_id != t.dr_id
		     	OR s.dc_id != t.dc_id
		     	OR s.operation_value != t.operation_value
		     	OR s.discharge_id != t.discharge_id
		     	OR s.rotaiting != t.rotaiting
		     	OR s.dc_coefficient != t.dc_coefficient
		     	OR s.comment_id != t.comment_id
		     ) THEN 
		     UPDATE	
		     SET 	t.ct_id = s.ct_id,
		     		t.ta_id = s.ta_id,
		     		t.element_id = s.element_id,
		     		t.equipment_id = s.equipment_id,
		     		t.dr_id = s.dr_id,
		     		t.dc_id = s.dc_id,
		     		t.operation_value = s.operation_value,
		     		t.discharge_id = s.discharge_id,
		     		t.rotaiting = s.rotaiting,
		     		t.dc_coefficient = s.dc_coefficient,
		     		t.comment_id = s.comment_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		spcv_id,
		     		operation_range,
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dr_id,
		     		dc_id,
		     		operation_value,
		     		discharge_id,
		     		rotaiting,
		     		dc_coefficient,
		     		employee_id,
		     		dt,
		     		comment_id
		     	)
		     VALUES
		     	(
		     		s.spcv_id,
		     		s.operation_range,
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dr_id,
		     		s.dc_id,
		     		s.operation_value,
		     		s.discharge_id,
		     		s.rotaiting,
		     		s.dc_coefficient,
		     		s.employee_id,
		     		s.dt,
		     		s.comment_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		COMMIT TRANSACTION
		
		SELECT	plpts.plpts_id,
				plpts.spcv_id,
				plpts.operation_range,
				plpts.ct_id,
				plpts.ta_id,
				plpts.element_id,
				plpts.equipment_id,
				plpts.operation_time,
				e.equipment_name,
				plpts.operation_time * st.qty work_time
		FROM	Planing.PlantLoadingPlan_TechnologicalSequence plpts   
				INNER JOIN	Technology.Equipment e
					ON	e.equipment_id = plpts.equipment_id   
				INNER JOIN	@spcv_tab st
					ON	plpts.spcv_id = st.spcv_id
		ORDER BY
			plpts.spcv_id,
			plpts.operation_range
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