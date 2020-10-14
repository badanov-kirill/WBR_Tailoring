CREATE PROCEDURE [Synchro].[DownloadUPD_DocClose]
	@employee_id INT,
	@doc_upd dbo.List READONLY
AS
	SET NOCOUNT ON
	
	DECLARE @dt             DATETIME2(0) = GETDATE(),
	        @error_text     VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN COUNT(1) = 0 THEN 'Не передано ни одного УПД'
	      	                   WHEN COUNT(d.id) != COUNT(dud.dud_id) THEN 'Передан некорректный список УПД'
	      	                   WHEN MAX(ISNULL(dud.dt_proc, '')) != '' THEN 'Выбранные УПД содержат уже обработанные строки.'
	      	                   ELSE NULL
	      	              END
	FROM	@doc_upd d   
			LEFT JOIN	Synchro.DownloadUPD_Doc dud
				ON	dud.dud_id = d.id   
			LEFT JOIN	Suppliers.SupplierContract sc
				ON	sc.suppliercontract_erp_id = dud.suppliercontract_id   
			LEFT JOIN	Synchro.DownloadUPD_Mapping dum
				ON	dum.esf_id = dud.esf_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		UPDATE	dud
		SET 	dud.dt_proc = @dt
		FROM	Synchro.DownloadUPD_Doc dud
				INNER JOIN	@doc_upd d
					ON	dud.dud_id = d.id
		WHERE	dud.dt_proc IS NULL
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
GO