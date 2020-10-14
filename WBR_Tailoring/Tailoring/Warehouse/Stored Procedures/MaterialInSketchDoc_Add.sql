CREATE PROCEDURE [Warehouse].[MaterialInSketchDoc_Add]
	@office_id INT,
	@employee_id INT,
	@data_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @data_tab TABLE (mis_id INT)
	DECLARE @misd_out TABLE (misd_id INT)
	DECLARE @upload_doc_type_id TINYINT = 3
	DECLARE @upload_buh_detail TABLE (rmt_id INT NOT NULL, nds TINYINT NOT NULL, amount DECIMAL(9, 2) NOT NULL)
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Settings.OfficeSetting os
	   	WHERE	os.office_id = @office_id
	   )
	BEGIN
	    RAISERROR('Офиса с кодом %d не существует', 16, 1, @office_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			mis_id
		)
	SELECT	ml.value('@mis[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@data_tab dt
	   )
	BEGIN
	    RAISERROR('Передано 0 строк для табличной части документа', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN mis.mis_id IS NULL THEN 'ШК с идентификатором списания ' + CAST(dt.mis_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN mis.mis_id IS NOT NULL AND sma.final_dt IS NULL THEN 'ШК ' + CAST(mis.shkrm_id AS VARCHAR(10)) +
	      	                        ' не имеет конечной стоимости'
	      	                   WHEN mis.mis_id IS NOT NULL AND sma.amount = 0 THEN 'ШК ' + CAST(mis.shkrm_id AS VARCHAR(10)) + ' имеет 0 стоимость'
	      	                   WHEN mis.misd_id IS NOT NULL THEN 'ШК ' + CAST(mis.shkrm_id AS VARCHAR(10)) + ' уже в документе № ' + CAST(mis.misd_id AS VARCHAR(10))
	      	                   WHEN mis.return_dt IS NULL THEN 'По ШК ' + CAST(mis.shkrm_id AS VARCHAR(10)) + ' не вернули остаток'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Warehouse.MaterialInSketch mis
				ON	mis.mis_id = dt.mis_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = mis.shkrm_id
	WHERE	mis.mis_id IS NULL
			OR	sma.final_dt IS NULL
			OR	sma.amount = 0
			OR	mis.misd_id IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	;
	WITH cte AS
	(
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				rmt.rmt_id                   root_rmt_id
		FROM	Material.RawMaterialType     rmt
		WHERE	rmt.rmt_pid IS NULL 
		UNION ALL
		SELECT	rmt.rmt_id,
				rmt.rmt_pid,
				c.root_rmt_id root_rmt_id
		FROM	Material.RawMaterialType rmt   
				INNER JOIN	cte c
					ON	c.rmt_id = rmt.rmt_pid
	)
	INSERT INTO @upload_buh_detail
		(
			rmt_id,
			nds,
			amount
		)
	SELECT	c.root_rmt_id,
			smi.nds,
			SUM((mis.stor_unit_residues_qty - ISNULL(mis.return_qty, 0)) * (sma.amount / sma.stor_unit_residues_qty)) amount
	FROM	@data_tab dt   
			INNER JOIN	Warehouse.MaterialInSketch mis
				ON	mis.mis_id = dt.mis_id   
			INNER JOIN	Warehouse.SHKRawMaterialInfo smi
				ON	smi.shkrm_id = mis.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
				ON	sma.shkrm_id = mis.shkrm_id   
			INNER JOIN	cte c
				ON	smi.rmt_id = c.rmt_id
	WHERE	smi.doc_type_id = 1
			AND c.root_rmt_id != 144
	GROUP BY
		c.root_rmt_id,
		smi.nds		
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		INSERT INTO Warehouse.MaterialInSketchDoc
			(
				create_dt,
				employee_id,
				office_id
			)OUTPUT	INSERTED.misd_id
			 INTO	@misd_out (
			 		misd_id
			 	)
		VALUES
			(
				@dt,
				@employee_id,
				@office_id
			)
		
		UPDATE	mis
		SET 	misd_id = mo.misd_id
		FROM	Warehouse.MaterialInSketch mis
				INNER JOIN	@data_tab dt
					ON	dt.mis_id = mis.mis_id
				CROSS JOIN	@misd_out mo
		WHERE	mis.misd_id IS NULL
		
		IF @@ROWCOUNT != (
		   	SELECT	COUNT(dt.mis_id)
		   	FROM	@data_tab dt
		   )
		BEGIN
		    RAISERROR('Чтото пошло не так, перечитайте данные и попробуйте снова', 16, 1)
		    RETURN
		END
		
		DELETE	
		FROM	Synchro.UploadBuh_DocDetail
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	@misd_out mo
		     		WHERE	mo.misd_id = doc_id
		     	)
				AND	upload_doc_type_id = @upload_doc_type_id
		
		INSERT INTO Synchro.UploadBuh_DocDetail
			(
				doc_id,
				upload_doc_type_id,
				rmt_id,
				nds,
				amount
			)
		SELECT	mo.misd_id,
				@upload_doc_type_id,
				ubd.rmt_id,
				ubd.nds,
				ubd.amount
		FROM	@upload_buh_detail ubd   
				CROSS JOIN	@misd_out mo
		
		DELETE	
		FROM	Synchro.UploadBuh_Doc
		WHERE	EXISTS (
		     		SELECT	1
		     		FROM	@misd_out mo
		     		WHERE	mo.misd_id = doc_id
		     	)
				AND	upload_doc_type_id = @upload_doc_type_id
		
		INSERT INTO Synchro.UploadBuh_Doc
			(
				doc_id,
				upload_doc_type_id,
				suppliercontract_code,
				supplier_id,
				is_deleted,
				office_id,
				doc_dt
			)
		SELECT	mo.misd_id,
				@upload_doc_type_id,
				NULL,
				NULL,
				0,
				@office_id,
				@dt
		FROM	@misd_out mo
		
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