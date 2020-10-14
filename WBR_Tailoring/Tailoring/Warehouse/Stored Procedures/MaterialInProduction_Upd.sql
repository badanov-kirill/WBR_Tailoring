CREATE PROCEDURE [Warehouse].[MaterialInProduction_Upd]
	@mip_id INT,
	@employee_id INT,
	@rv_bigint BIGINT,
	@workshop_id INT
AS

	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	DECLARE @with_log BIT = 1
	
	SELECT	@error_text = CASE 
	      	                   WHEN mip.mip_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.mip_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN mip.complite_dt IS NOT NULL THEN 'Заказ в производство закрыт, изменять нельзя'
	      	                   WHEN mip.rv != @rv THEN 'Документ уже кто-то поменял, перечитайте данные и попробуйте снова'
	      	                   WHEN oa.is_shk IS NOT NULL AND mip.workshop_id != @workshop_id THEN 'Нельзя менять цех, уже есть выданные ШК'
	      	                   WHEN oa2.mip_id IS NOT NULL AND mip.workshop_id != @workshop_id THEN 
	      	                        'После смены цеха, получится два документа запука артикула в производство одного цеха. Пересечение с документом ' + CAST(oa2.mip_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@mip_id))v(mip_id)   
			LEFT JOIN	Warehouse.MaterialInProduction mip
				ON	mip.mip_id = v.mip_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_shk
			      	FROM	Warehouse.MaterialInProductionDetailShk mipds
			      	WHERE	mipds.mip_id = mip.mip_id
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP 1 mip2.mip_id
	      	FROM	Warehouse.MaterialInProductionDetailNom mipdn2   
	      			INNER JOIN	Warehouse.MaterialInProduction mip2
	      				ON	mip2.mip_id = mipdn2.mip_id
	      	WHERE	mip2.complite_dt IS NULL
	      			AND	mip2.workshop_id = @workshop_id
	      			AND	mip2.mip_id != mip.mip_id
	      			AND	EXISTS(
	      			   		SELECT	1
	      			   		FROM	Warehouse.MaterialInProductionDetailNom mipdn3
	      			   		WHERE	mipdn3.mip_id = mip.mip_id
	      			   				AND	mipdn3.pan_id = mipdn2.pan_id
	      			   	)
	      ) oa2
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Warehouse.MaterialInProduction
		SET 	dt = @dt,
				employee_id = @employee_id,
				workshop_id = @workshop_id
				OUTPUT	CAST(CAST(INSERTED.rv AS BIGINT) AS VARCHAR(19)) rv_bigint,
						INSERTED.workshop_id
		WHERE	mip_id = @mip_id
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