CREATE PROCEDURE [Planing].[SketchPrePlan_TechnologicalSequence_Set]
	@start_dt DATE,
	@finish_dt DATE,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE() 
	DECLARE @spp_tab TABLE (spp_id INT, sketch_id INT, ct_id INT, pt_id TINYINT, control_work_time INT, perimetr DECIMAL(15, 5), max_operation INT, qty SMALLINT)
	
	INSERT INTO @spp_tab
		(
			spp_id,
			sketch_id,
			ct_id,
			pt_id,
			control_work_time,
			perimetr,
			max_operation,
			qty
		)
	SELECT	sppl.spp_id,
			sppl.sketch_id,
			s.ct_id,
			s.pt_id,
			pt.work_time,
			oa.perimetr,
			oa_ts.max_operation,
			sppl.plan_qty
	FROM	Planing.SketchPrePlan sppl   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sppl.sketch_id   
			INNER JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			OUTER APPLY (
			      	SELECT	AVG(spp.perimetr) perimetr
			      	FROM	Products.SketchPatternPerimetr spp
			      	WHERE	spp.sketch_id = sppl.sketch_id
			      ) oa
			OUTER APPLY (
	      			SELECT	MAX(ts.operation_range) max_operation
	      			FROM	Products.TechnologicalSequence ts
	      			WHERE	ts.sketch_id = sppl.sketch_id
				  ) oa_ts
	WHERE	sppl.plan_dt >= @start_dt
			AND	sppl.plan_dt <= @finish_dt
			AND oa_ts.max_operation > 5
			AND oa.perimetr IS NOT NULL
	
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	spptsw
		FROM	Planing.SketchPrePlan_TechnologicalSequenceWork spptsw   
				INNER JOIN	Planing.SketchPrePlan_TechnologicalSequence sppts
					ON	sppts.sppts_id = spptsw.sppts_id   
				INNER JOIN	Planing.SketchPrePlan spp
					ON	spp.spp_id = sppts.spp_id
		WHERE	spp.plan_dt >= @start_dt
				AND	spp.plan_dt <= @finish_dt
		
		;WITH cte_Target AS
		(
			SELECT	sppts.spp_id,
					sppts.operation_range,
					sppts.ct_id,
					sppts.ta_id,
					sppts.element_id,
					sppts.equipment_id,
					sppts.dr_id,
					sppts.dc_id,
					sppts.operation_value,
					sppts.discharge_id,
					sppts.rotaiting,
					sppts.dc_coefficient,
					sppts.employee_id,
					sppts.dt,
					sppts.operation_time,
					sppts.comment_id
			FROM	Planing.SketchPrePlan_TechnologicalSequence sppts
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@spp_tab spp
			     		WHERE	spp.spp_id = sppts.spp_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	spp.spp_id,
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
		      	FROM	@spp_tab spp   
		      			INNER JOIN	Products.TechnologicalSequence ts
		      				ON	ts.sketch_id = spp.sketch_id
		      	UNION
		      	ALL
		      	SELECT	st.spp_id     spp_id,
		      			0             operation_range,
		      			st.ct_id      ct_id,
		      			108           ta_id,	--разрезать
		      			580           element_id,	--изделие
		      			26            equipment_id,	--Раскройный стол
		      			2             dr_id,	--средняя
		      			1             dc_id,	--Без совмещения рисунка
		      			1             operation_value,
		      			1             discharge_id,
		      			CAST(st.perimetr / 55 AS INT),
		      			1             dc_coefficient,
		      			@employee_id,
		      			@dt,
		      			2472
		      	FROM	@spp_tab      st
		      	UNION
		      	ALL 
		      	SELECT	st.spp_id,
		      			st.max_operation + 1 operation_range,
		      			st.ct_id     ct_id,
		      			99           ta_id,	--проверить
		      			580          element_id,	--изделие
		      			27           equipment_id,	--Стол контроля качества и упаковки
		      			2            dr_id,	--средняя
		      			1            dc_id,	--Без совмещения рисунка
		      			1            operation_value,
		      			1            discharge_id,
		      			st.control_work_time,
		      			1            dc_coefficient,
		      			@employee_id,
		      			@dt,
		      			2473
		      	FROM	@spp_tab     st
		      ) s
				ON s.spp_id = t.spp_id
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
		     		spp_id,
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
		     		s.spp_id,
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
		
		SELECT	sppts.sppts_id,
				sppts.spp_id,
				sppts.operation_range,
				sppts.ct_id,
				sppts.ta_id,
				sppts.element_id,
				sppts.equipment_id,
				sppts.operation_time,
				e.equipment_name,
				sppts.operation_time * st.qty work_time
		FROM	Planing.SketchPrePlan_TechnologicalSequence sppts   
				INNER JOIN	Technology.Equipment e
					ON	e.equipment_id = sppts.equipment_id   
				INNER JOIN	@spp_tab st
					ON	sppts.spp_id = st.spp_id
		ORDER BY
			sppts.spp_id,
			sppts.operation_range
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