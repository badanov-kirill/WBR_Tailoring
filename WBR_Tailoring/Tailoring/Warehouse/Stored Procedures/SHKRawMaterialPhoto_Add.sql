CREATE PROCEDURE [Warehouse].[SHKRawMaterialPhoto_Add]
	@shkrm_id INT,
	@employee_id INT,
	@rmtp_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	DECLARE @error_text VARCHAR(MAX)
	
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmtp.rmtp_id IS NULL THEN 'Код ' + CAST(v.rmtp_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(@shkrm_id AS VARCHAR(10)) + ' не описан, возможно он уже удален.'
	      	                   WHEN rmtp.rmtp_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND rmtp.rmt_id != smai.rmt_id THEN 
	      	                        'Не совпадает тип материала шк и кода фото'
	      	                   WHEN rmtp.rmtp_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND rmtp.art_id != smai.art_id THEN 
	      	                        'Не совпадает артикул материала шк и фото'
	      	                   WHEN rmtp.rmtp_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND rmtp.color_id != smai.color_id THEN 
	      	                        'Не совпадает цвет материала шк и фото'
	      	                   WHEN rmtp.rmtp_id IS NOT NULL AND smai.shkrm_id IS NOT NULL AND ISNULL(rmtp.frame_width, 0) != ISNULL(smai.frame_width, 0) THEN 
	      	                        'Не совпадает рамка материала шк и фото'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmtp_id))v(rmtp_id)   
			LEFT JOIN	Material.RawMaterialTypePhoto rmtp
				ON	rmtp.rmtp_id = v.rmtp_id   
			LEFT JOIN	Warehouse.SHKRawMaterialInfo smai
				ON	smai.shkrm_id = @shkrm_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Warehouse.SHKRawMaterialPhoto
			(
				shkrm_id,
				employee_id,
				dt,
				rmtp_id
			)
		VALUES
			(
				@shkrm_id,
				@employee_id,
				@dt,
				@rmtp_id
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
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 