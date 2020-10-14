CREATE PROCEDURE [Material].[RawMaterialInvoiceCorrection_Create]
	@rmi_id INT,
	@data_xml XML,
	@comment VARCHAR(500),
	@employee_id INT,
	@buch_num VARCHAR(30),
	@rmict_id TINYINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @amount_inv DECIMAL(15, 2)
	DECLARE @data_tab TABLE (rmid_id INT, return_qty DECIMAL(9, 3), item_number SMALLINT, rmt_id INT)
	DECLARE @rmic_id INT
	
	IF NOT EXISTS (SELECT 1 FROM Material.RawMaterialInvoiceCorrectionType rmict WHERE rmict.rmict_id = @rmict_id)
	BEGIN
		RAISERROR('Типа с кодом %d не существует', 16,1, @rmict_id)
		RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmi.rmi_id IS NULL THEN 'Счет фактуры с идентификатором ' + CAST(v.rmi_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmic.rmis_id != 7 THEN 'Документ ещё не закрыт менеджером, корректировать нельзя.'
	      	                   WHEN rmi.is_deleted = 1 THEN 'Счет фактуры с идентификатором ' + CAST(v.rmi_id AS VARCHAR(10)) + ' удалена.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmi_id))v(rmi_id)   
			LEFT JOIN	Material.RawMaterialInvoice rmi   
			INNER JOIN	Material.RawMaterialIncome rmic
				ON	rmic.doc_id = rmi.doc_id
				AND	rmic.doc_type_id = rmi.doc_type_id
				ON	rmi.rmi_id = v.rmi_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO 
	       @data_tab
		(
			rmid_id,
			return_qty,
			item_number,
			rmt_id
		)
	SELECT	ml.value('@id', 'int'),
			ml.value('@qty', 'decimal(15,2)'),
			ml.value('@in', 'smallint'),
			ml.value('@rmt', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.rmid_id IS NULL THEN 'Не корректный ХМЛ'
	      	                   WHEN dt.rmid_id IS NOT NULL AND rmid.rmid_id IS NULL THEN 'Детали СФ с кодом ' + CAST(dt.rmid_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN ISNULL(dt.return_qty, 0) = 0 THEN 'Есть делали СФ с неуказаныым количеством возврата.'
	      	                   WHEN dt.return_qty > rmid.quantity - oa.sum_qty THEN 'У позиции СФ с порядковым номером ' + CAST(rmid.item_number AS VARCHAR(10)) 
	      	                        + ' указано количество возврата, превышающее допустимый остаток.'
	      	                   WHEN rmid.rmi_id != @rmi_id THEN 'Детали СФ с кодом ' + CAST(dt.rmid_id AS VARCHAR(10)) +
	      	                        ' относится к другой счет фактуре.'
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Указан не верный тип материала с кодом :' + CAST(dt.rmt_id AS VARCHAR(10))
	      	                   WHEN rmt.rmt_pid IS NOT NULL THEN 'Указан тип материала с кодом :' + CAST(dt.rmt_id AS VARCHAR(10)) + ' не верхнего уровня.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Material.RawMaterialInvoiceDetail rmid
				ON	rmid.rmid_id = dt.rmid_id 
			LEFT JOIN Material.RawMaterialType rmt 
				ON rmt.rmt_id = dt.rmt_id  
			OUTER APPLY (
			      	SELECT	SUM(rmicid.return_quantity) sum_qty
			      	FROM	Material.RawMaterialInvoiceCorrectionInvoiceDetail rmicid
			      	WHERE	rmicid.rmid_id = dt.rmid_id
			      ) oa
	WHERE dt.rmid_id IS NULL
	OR rmid.rmid_id IS NULL
	OR ISNULL(dt.return_qty, 0) = 0
	OR dt.return_qty > rmid.quantity - oa.sum_qty
	OR rmid.rmi_id != @rmi_id
	OR rmt.rmt_id IS NULL
	OR rmt.rmt_pid IS NOT NULL		      
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SET @amount_inv = (
	    	SELECT	SUM(ROUND(rmid.amount_with_nds * (dt.return_qty / rmid.quantity), 2))
	    	FROM	@data_tab dt   
	    			LEFT JOIN	Material.RawMaterialInvoiceDetail rmid
	    				ON	rmid.rmid_id = dt.rmid_id
	    )
	
	BEGIN TRY
		BEGIN TRANSACTION		
		
		INSERT INTO Material.RawMaterialInvoiceCorrection
			(
				rmi_id,
				base_invoice_name,
				base_invoice_dt,
				buch_num,
				create_dt,
				create_employee_id,
				dt,
				employee_id,
				comment,
				close_dt,
				close_employee_id,
				amount_invoice,
				amount_shk,
				rmict_id
			)
		SELECT	rmi.rmi_id,
				rmi.invoice_name,
				rmi.invoice_dt,
				@buch_num,
				@dt,
				@employee_id,
				@dt,
				@employee_id,
				@comment,
				NULL,
				NULL,
				@amount_inv,
				0,
				@rmict_id
		FROM	Material.RawMaterialInvoice rmi
		WHERE	rmi.rmi_id = @rmi_id
		
		SET @rmic_id = SCOPE_IDENTITY()
		
		INSERT INTO Material.RawMaterialInvoiceCorrectionInvoiceDetail
			(
				rmic_id,
				rmid_id,
				rmii_id,
				price,
				base_quantity,
				base_amount_with_nds,
				base_amount_nds,
				base_amount_without_nds,
				nds,
				okei_id,
				country_id,
				gtd_id,
				base_item_number,
				return_quantity,
				item_number,
				rmt_id				
			)
		SELECT	@rmic_id,
				rmid.rmid_id,
				rmid.rmii_id,
				rmid.price,
				rmid.quantity,
				rmid.amount_with_nds,
				rmid.amount_nds,
				rmid.amount_without_nds,
				rmid.nds,
				rmid.okei_id,
				rmid.country_id,
				rmid.gtd_id,
				rmid.item_number,
				dt.return_qty,
				dt.item_number,
				dt.rmt_id
		FROM	Material.RawMaterialInvoiceDetail rmid   
				INNER JOIN	@data_tab dt
					ON	dt.rmid_id = rmid.rmid_id
		
		COMMIT TRANSACTION
		
		SELECT	@rmic_id rmic_id
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