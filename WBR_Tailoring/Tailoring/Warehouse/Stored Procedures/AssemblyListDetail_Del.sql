CREATE PROCEDURE [Warehouse].[AssemblyListDetail_Del]
	@al_id INT,
	@shkrm_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN al.al_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.al_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN al.close_dt IS NOT NULL THEN 'Документ закрыт, изменять нельзя'
	      	                   WHEN oa.is_shk IS NULL THEN 'ШК ' + CAST(@shkrm_id AS VARCHAR(10)) + ' нет в документе.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@al_id))v(al_id)   
			LEFT JOIN	Warehouse.AssemblyList al
				ON	al.al_id = v.al_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_shk
			      	FROM	Warehouse.AssemblyListDetail asd
			      	WHERE	asd.al_id = al.al_id
			      			AND	asd.shkrm_id = @shkrm_id
			      ) oa	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Warehouse.AssemblyListDetail
		WHERE	al_id = @al_id
				AND	shkrm_id = @shkrm_id
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
	