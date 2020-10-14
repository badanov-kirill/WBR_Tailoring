CREATE PROCEDURE [Technology].[EquipmentMapping_Add]
	@ct_id INT,
	@ta_id INT,
	@equipment_id INT,
	@discharge_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.TechAction ta
	   	WHERE	ta.ta_id = @ta_id
	   			AND	ta.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Действия с кодом %d не существует', 16, 1, @ta_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.ClothType ct
	   	WHERE	ct.ct_id = @ct_id
	   )
	BEGIN
	    RAISERROR('Ткани с кодом %d не существует', 16, 1, @ct_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.Equipment e
	   	WHERE	e.equipment_id = @equipment_id
	   )
	BEGIN
	    RAISERROR('Оборудования с кодом %d не существует', 16, 1, @equipment_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Technology.Discharge d
	   	WHERE	d.discharge_id = @discharge_id
	   )
	BEGIN
	    RAISERROR('Разряда %d не существует', 16, 1, @discharge_id)
	    RETURN
	END
	
	BEGIN TRY
		MERGE Technology.EquipmentMapping t
		USING (
		      	SELECT	@ct_id            ct_id,
		      			@ta_id            ta_id,
		      			@equipment_id     equipment_id,
		      			@discharge_id     discharge_id,
		      			@dt               dt,
		      			@employee_id      employee_id
		      ) s
				ON t.ct_id = s.ct_id
				AND t.ta_id = s.ta_id
				AND t.equipment_id = s.equipment_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	discharge_id     = s.discharge_id,
		     		dt               = s.dt,
		     		employee_id      = s.employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		ct_id,
		     		ta_id,
		     		equipment_id,
		     		discharge_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.ct_id,
		     		s.ta_id,
		     		s.equipment_id,
		     		s.discharge_id,
		     		s.dt,
		     		s.employee_id
		     	);
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