CREATE PROCEDURE [Warehouse].[AssemblyList_Upd]
	@al_id INT,
	@employee_id INT,
	@rv_bigint BIGINT,
	@workshop_id INT,
	@shipping_dt DATE
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @with_log BIT = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN al.al_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.al_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN al.close_dt IS NOT NULL THEN 'Документ закрыт, изменять нельзя'
	      	                   WHEN al.rv != @rv THEN 'Документ уже кто-то поменял, перечитайте данные и попробуйте снова'
	      	                   WHEN oa.is_shk IS NOT NULL AND al.workshop_id != @workshop_id THEN 'Нельзя менять цех, уже есть запиканные ШК'
	      	                   WHEN oa2.al_id IS NOT NULL THEN 'Уже есть не закрытый документ в этот цех'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@al_id))v(al_id)   
			LEFT JOIN	Warehouse.AssemblyList al
				ON	al.al_id = v.al_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_shk
			      	FROM	Warehouse.AssemblyListDetail asd
			      	WHERE	asd.al_id = al.al_id
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP(1) al2.al_id
	      	FROM	Warehouse.AssemblyList al2
	      	WHERE	al2.al_id != al.al_id
	      			AND	al2.workshop_id = @workshop_id
	      			AND	al2.close_dt IS NULL
	      ) oa2
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Warehouse.AssemblyList
		SET 	workshop_id = @workshop_id,
				shipping_dt = @shipping_dt,
				dt = @dt,
				employee_id = @employee_id 	
				OUTPUT	CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(19)) rv_bigint,
						INSERTED.workshop_id
		WHERE	al_id = @al_id
				AND	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Документ уже кто-то поменял, перечитайте данные и попробуйте снова', 16, 1);
		    RETURN
		END
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 