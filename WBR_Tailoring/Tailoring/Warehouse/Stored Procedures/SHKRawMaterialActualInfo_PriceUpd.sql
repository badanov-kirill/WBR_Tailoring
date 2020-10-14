CREATE PROCEDURE [Warehouse].[SHKRawMaterialActualInfo_PriceUpd]
	@shkrm_id INT,
	@price DECIMAL(9, 2),
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @proc_id INT
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN sma.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = sm.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Warehouse.SHKRawMaterialAmount
		SET 	amount = @price * stor_unit_residues_qty,
				final_dt = @dt		    	
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.stor_unit_residues_okei_id,
						INSERTED.stor_unit_residues_qty,
						INSERTED.amount,
						INSERTED.gross_mass,
						@proc_id,
						@dt,
						@employee_id
				INTO	History.SHKRawMaterialAmount (
						shkrm_id,
						stor_unit_residues_okei_id,
						stor_unit_residues_qty,
						amount,
						gross_mass,
						proc_id,
						dt,
						employee_id
					)
		WHERE	shkrm_id = @shkrm_id 
		
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