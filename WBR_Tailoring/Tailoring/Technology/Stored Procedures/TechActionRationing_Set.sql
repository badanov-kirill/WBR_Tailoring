CREATE PROCEDURE [Technology].[TechActionRationing_Set]
	@data_roaming_xml XML,
	@data_dc_coeff_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @data_tab_roaming TABLE (id INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED, ct_id INT, ta_id INT, element_id INT, equipment_id INT, dr_id TINYINT, rotaiting DECIMAL(9, 5))
	
	DECLARE @data_tab_dc_coefficient TABLE (id INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED, ct_id INT, ta_id INT, element_id INT, equipment_id INT, dc_id TINYINT, dc_coefficient DECIMAL(9, 5))
	
	INSERT INTO @data_tab_roaming
	  (
	    ct_id,
	    ta_id,
	    element_id,
	    equipment_id,
	    dr_id,
	    rotaiting
	  )
	SELECT	ml.value('@ct', 'int'),
			ml.value('@ta', 'int'),
			ml.value('@el', 'int'),
			ml.value('@eq', 'int'),
			ml.value('@dr', 'tinyint'),
			ml.value('@rot', 'decimal(9,5)')
	FROM	@data_roaming_xml.nodes('root/detail')x(ml)
	
	INSERT INTO @data_tab_dc_coefficient
	  (
	    ct_id,
	    ta_id,
	    element_id,
	    equipment_id,
	    dc_id,
	    dc_coefficient
	  )
	SELECT	ml.value('@ct', 'int'),
			ml.value('@ta', 'int'),
			ml.value('@el', 'int'),
			ml.value('@eq', 'int'),
			ml.value('@dc', 'tinyint'),
			ml.value('@cof', 'decimal(9,5)')
	FROM	@data_dc_coeff_xml.nodes('root/detail')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ct.ct_id IS NULL THEN 'Типа ткани с кодом ' + CAST(dt.ct_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ta.ta_id IS NULL THEN 'Действия с кодом ' + CAST(dt.ta_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN e.element_id IS NULL THEN 'Элемента с кодом ' + CAST(dt.element_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN eq.equipment_id IS NULL THEN 'Оборудования с кодом ' + CAST(dt.equipment_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN dr.dr_id IS NULL THEN 'Сложности ткани с кодом ' + CAST(dt.dr_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ISNULL(dt.rotaiting, 0) = 0 THEN 'В строчке ' + CAST(dt.id AS VARCHAR(10)) + ' не заполнено значение нормы'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab_roaming dt   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = dt.ct_id   
			LEFT JOIN	Technology.TechAction ta
				ON	ta.ta_id = dt.ta_id   
			LEFT JOIN	Technology.Element e
				ON	e.element_id = dt.element_id   
			LEFT JOIN	Technology.Equipment eq
				ON	eq.equipment_id = dt.equipment_id   
			LEFT JOIN	Technology.DifficultyRebuffing dr
				ON	dr.dr_id = dt.dr_id
	WHERE	ct.ct_id IS NULL
			OR	ta.ta_id IS NULL
			OR	e.element_id IS NULL
			OR	eq.equipment_id IS NULL
			OR	dr.dr_id IS NULL
			OR	ISNULL(dt.rotaiting, 0) = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN ct.ct_id IS NULL THEN 'Типа ткани с кодом ' + CAST(dt.ct_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ta.ta_id IS NULL THEN 'Действия с кодом ' + CAST(dt.ta_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN e.element_id IS NULL THEN 'Элемента с кодом ' + CAST(dt.element_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN eq.equipment_id IS NULL THEN 'Оборудования с кодом ' + CAST(dt.equipment_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN dc.dc_id IS NULL THEN 'Сложности рисунка с кодом ' + CAST(dt.dc_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ISNULL(dt.dc_coefficient, 0) = 0 THEN 'В строчке ' + CAST(dt.id AS VARCHAR(10)) +
	      	                        ' не заполнено значение коэффициента сложности рисунка'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab_dc_coefficient dt   
			LEFT JOIN	Material.ClothType ct
				ON	ct.ct_id = dt.ct_id   
			LEFT JOIN	Technology.TechAction ta
				ON	ta.ta_id = dt.ta_id   
			LEFT JOIN	Technology.Element e
				ON	e.element_id = dt.element_id   
			LEFT JOIN	Technology.Equipment eq
				ON	eq.equipment_id = dt.equipment_id   
			LEFT JOIN	Technology.DrawingComplexity dc
				ON	dc.dc_id = dt.dc_id
	WHERE	ct.ct_id IS NULL
			OR	ta.ta_id IS NULL
			OR	e.element_id IS NULL
			OR	eq.equipment_id IS NULL
			OR	dc.dc_id IS NULL
			OR	ISNULL(dt.dc_coefficient, 0) = 0 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		MERGE Technology.TechActionRationing t
		USING @data_tab_roaming s
				ON s.ct_id = t.ct_id
				AND s.ta_id = t.ta_id
				AND s.element_id = t.element_id
				AND s.equipment_id = t.equipment_id
				AND s.dr_id = t.dr_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	rotaiting = s.rotaiting
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dr_id,
		     		rotaiting
		     	)
		     VALUES
		     	(
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dr_id,
		     		s.rotaiting
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	OUTPUT	ISNULL(INSERTED.ct_id, DELETED.ct_id),
		           			ISNULL(INSERTED.ta_id, DELETED.ta_id),
		           			ISNULL(INSERTED.element_id, DELETED.element_id),
		           			ISNULL(INSERTED.equipment_id, DELETED.equipment_id),
		           			ISNULL(INSERTED.dr_id, DELETED.dr_id),
		           			ISNULL(INSERTED.rotaiting, DELETED.rotaiting),
		           			@dt,
		           			@employee_id,
		           			UPPER(LEFT($action, 1))
		           	INTO	History.TechActionRationing (
		           			ct_id,
		           			ta_id,
		           			element_id,
		           			equipment_id,
		           			dr_id,
		           			rotaiting,
		           			dt,
		           			employee_id,
		           			operation
		           		);
		
		MERGE Technology.TechActionDCCoefficient t
		USING @data_tab_dc_coefficient s
				ON s.ct_id = t.ct_id
				AND s.ta_id = t.ta_id
				AND s.element_id = t.element_id
				AND s.equipment_id = t.equipment_id
				AND s.dc_id = t.dc_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	dc_coefficient = s.dc_coefficient
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		ct_id,
		     		ta_id,
		     		element_id,
		     		equipment_id,
		     		dc_id,
		     		dc_coefficient
		     	)
		     VALUES
		     	(
		     		s.ct_id,
		     		s.ta_id,
		     		s.element_id,
		     		s.equipment_id,
		     		s.dc_id,
		     		s.dc_coefficient
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	OUTPUT	ISNULL(INSERTED.ct_id, DELETED.ct_id),
		           			ISNULL(INSERTED.ta_id, DELETED.ta_id),
		           			ISNULL(INSERTED.element_id, DELETED.element_id),
		           			ISNULL(INSERTED.equipment_id, DELETED.equipment_id),
		           			ISNULL(INSERTED.dc_id, DELETED.dc_id),
		           			ISNULL(INSERTED.dc_coefficient, DELETED.dc_coefficient),
		           			@dt,
		           			@employee_id,
		           			UPPER(LEFT($action, 1))
		           	INTO	History.TechActionDCCoefficient (
		           			ct_id,
		           			ta_id,
		           			element_id,
		           			equipment_id,
		           			dc_id,
		           			dc_coefficient,
		           			dt,
		           			employee_id,
		           			operation
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
		WITH LOG;
	END CATCH 