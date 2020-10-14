CREATE PROCEDURE [Technology].[EquipmentMapping_Del]
	@ct_id INT,
	@ta_id INT,
	@equipment_id INT
AS
	SET NOCOUNT ON
	
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
	
	BEGIN TRY
		DELETE	
		FROM	Technology.EquipmentMapping
		WHERE	ct_id = @ct_id
				AND	ta_id = @ta_id
				AND	equipment_id = @equipment_id
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