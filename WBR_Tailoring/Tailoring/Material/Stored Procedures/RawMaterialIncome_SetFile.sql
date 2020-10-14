CREATE PROCEDURE [Material].[RawMaterialIncome_SetFile]
	@doc_id INT,
	@rmi_id INT,
	@ext VARCHAR(20)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @doc_type_id     TINYINT = 1,
	        @dt              DATETIME2(0) = GETDATE(),
	        @error_text      VARCHAR(MAX),
	        @file_ext_id     SMALLINT
	
	SELECT	@error_text = CASE 
	      	                   WHEN rm_inc.doc_id IS NULL THEN 'Поступления материалов № ' + CAST(v.doc_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN rm_inc.is_deleted = 1 THEN 'Поступление материалов удалено'
	      	                   WHEN rmi.rmi_id IS NULL THEN 'Указанная СФ или удалена или не существует'
	      	                   WHEN rmi.doc_id <> v.doc_id THEN 'Указанная СФ принадлежит другому документу поступления №' + CAST(rmi.doc_id AS VARCHAR(10))
	      	                   WHEN rmi.set_file_dt IS NOT NULL AND rm_inc.rmis_id >= 7 THEN 'Документ закрыт'
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
	
	SELECT	@file_ext_id = fe.file_ext_id
	FROM	RefBook.FileExt fe
	WHERE	fe.file_ext_name = @ext
	
	BEGIN TRY
		IF @file_ext_id IS NULL
		BEGIN
		    INSERT INTO RefBook.FileExt
		    	(
		    		file_ext_name
		    	)
		    SELECT	@ext
		    WHERE	NOT EXISTS (
		         		SELECT	1
		         		FROM	RefBook.FileExt fe
		         		WHERE	fe.file_ext_name = @ext
		         	)
		    
		    SELECT	@file_ext_id = fe.file_ext_id
		    FROM	RefBook.FileExt fe
		    WHERE	fe.file_ext_name = @ext
		END
		
		BEGIN TRANSACTION
		
		UPDATE	Material.RawMaterialInvoice
		SET 	set_file_dt = @dt,
				file_ext_id = @file_ext_id
		WHERE	rmi_id = @rmi_id 
		
		
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