CREATE PROCEDURE [Planing].[PlanShippingDetail_Add]
	@ps_id INT,
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @stor_unit_residues_okei_id INT
	DECLARE @stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @gross_mass INT
	DECLARE @ttn_id INT
	DECLARE @ttnd_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN ps.ps_id IS NULL THEN 'Плановой отгрузки с номером ' + CAST(v.ps_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN ps.close_dt IS NOT NULL THEN 'Эта отгрузка уже закрыта'
	      	                   ELSE NULL
	      	              END,
	      	@ttn_id = ps.ttn_id
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
	      	                   WHEN psd.shkrm_id IS NOT NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' уже в плановой отгрузке № ' + CAST(psd.ps_id AS VARCHAR(10))
	      	                        + ', которая не закрыта'
	      	                   ELSE NULL
	      	              END,
			@stor_unit_residues_okei_id     = smai.stor_unit_residues_okei_id,
			@stor_unit_residues_qty         = smai.stor_unit_residues_qty,
			@gross_mass                     = smai.gross_mass,
			@ttnd_id						= t.ttnd_id
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id   
			LEFT JOIN	Planing.PlanShippingDetail psd
				ON	psd.shkrm_id = sm.shkrm_id
				AND	psd.shipping_dt IS NULL
			LEFT JOIN Logistics.TTNDetail t
				ON t.shkrm_id = sm.shkrm_id
				AND t.ttn_id = @ttn_id
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Planing.PlanShippingDetail
			(
				ps_id,
				shkrm_id,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				employee_id,
				dt,
				gross_mass,
				ttnd_id
			)
		VALUES
			(
				@ps_id,
				@shkrm_id,
				@stor_unit_residues_okei_id,
				@stor_unit_residues_qty,
				@employee_id,
				@dt,
				@gross_mass,
				@ttnd_id
			)
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