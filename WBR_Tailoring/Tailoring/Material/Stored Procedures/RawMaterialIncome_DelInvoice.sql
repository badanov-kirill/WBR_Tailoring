CREATE PROCEDURE [Material].[RawMaterialIncome_DelInvoice]
	@doc_id INT,
	@rmi_id INT,
	@rv_bigint BIGINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id TINYINT = 1,
	        @dt DATETIME2(0) = GETDATE(),
	        @error_text VARCHAR(MAX),
	        @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)	
	
	DECLARE @income_output TABLE (rv_bigint BIGINT)         
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.rv != @rv THEN 'Документ уже кто-то поменял. Перечитайте данные и попробуйте записать снова.'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmi.rmi_id IS NULL THEN 'Указанная СФ или удалена или не существует'
	      	                   WHEN rmi.doc_id <> v.doc_id THEN 'Указанная СФ принадлежит другому документу поступления №' + CAST(rmi.doc_id AS VARCHAR(10))
	      	                   WHEN rmi.doc_id <> v.doc_id THEN 'Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' уже распределен'
	      	              END
	FROM	(VALUES(@doc_id,
			@doc_type_id,
			@rmi_id))v(doc_id,
			doc_type_id,
			rmi_id)   
			LEFT JOIN	Material.RawMaterialIncome rm_inc
				ON	rm_inc.doc_id = v.doc_id
				AND	rm_inc.doc_type_id = v.doc_type_id   
			LEFT JOIN	Material.RawMaterialInvoice rmi
				ON	rmi.rmi_id = v.rmi_id
				AND	rmi.is_deleted = 0   
			LEFT JOIN	Material.RawMaterialInvoiceRelationDetail rmird
				ON	rmird.doc_id = v.doc_id
				AND	rmird.doc_type_id = v.doc_type_id	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('(%s).', 16, 1, @error_text)
	    RETURN
	END	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Material.RawMaterialIncome
		SET 	employee_id = @employee_id,
				dt = @dt
				OUTPUT	CAST(INSERTED.rv AS BIGINT)
				INTO	@income_output (
						rv_bigint
					)
		WHERE	doc_id = @doc_id
				AND	doc_type_id = @doc_type_id
				AND	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже кто-то успел поменять. Перечитайте данные и попробуйте записать снова.', 16, 1)
		    RETURN
		END			
		
		UPDATE	Material.RawMaterialInvoice
		SET 	is_deleted = 1,
				employee_id = @employee_id
		WHERE	rmi_id = @rmi_id			
		
		DELETE	
		FROM	Material.RawMaterialInvoiceDetail
		WHERE	rmi_id = @rmi_id 
		
		UPDATE	dud
		SET 	dt_proc = NULL
		FROM	Synchro.DownloadUPD_Mapping d
				INNER JOIN	Synchro.DownloadUPD_Doc dud
					ON	dud.dud_id = d.dud_id
		WHERE	d.rmi_id = @rmi_id 				
		
		DELETE	d
		FROM	Synchro.DownloadUPD_Mapping d
		WHERE	d.rmi_id = @rmi_id
		
		COMMIT TRANSACTION
		
		SELECT	rv_bigint
		FROM	@income_output
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