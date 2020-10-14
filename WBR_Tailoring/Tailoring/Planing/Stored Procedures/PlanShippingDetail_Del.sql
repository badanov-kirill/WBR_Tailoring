CREATE PROCEDURE [Planing].[PlanShippingDetail_Del]
	@ps_id INT,
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN ps.ps_id IS NULL THEN 'Плановой отгрузки с номером ' + CAST(v.ps_id AS VARCHAR(10)) + ' не существует.'
	      	                   --WHEN ps.close_dt IS NOT NULL THEN 'Эта отгрузка уже закрыта'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@ps_id))v(ps_id)   
			LEFT JOIN	Planing.PlanShipping ps
				ON	ps.ps_id = v.ps_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан'
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN psd.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' нет в плановой отгрузке № ' + CAST(v.ps_id AS VARCHAR(10))
	      	                        + ', из которой вы его удаляете'
	      	                   WHEN psd.ttnd_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в отгрузке, удалять нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id,
			@ps_id))v(shkrm_id,
			ps_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Planing.PlanShippingDetail psd
				ON	psd.shkrm_id = v.shkrm_id
				AND	psd.ps_id = v.ps_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Planing.PlanShippingDetail
		WHERE	ps_id = @ps_id
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