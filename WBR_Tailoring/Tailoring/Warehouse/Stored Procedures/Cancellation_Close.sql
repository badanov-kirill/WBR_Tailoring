CREATE PROCEDURE [Warehouse].[Cancellation_Close]
	@cancellation_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @office_id INT
	DECLARE @doc_dt DATETIME2(0) 
	DECLARE @upload_doc_type_id TINYINT = 4
	DECLARE @upload_buh_detail     TABLE (rmt_id INT NOT NULL, nds TINYINT NOT NULL, amount DECIMAL(9, 2) NOT NULL)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.cancellation_id IS NULL THEN 'Документа списания с номером ' + CAST(v.cancellation_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Документ уже закрыт.'
	      	                   ELSE NULL
	      	              END,
	      	@office_id = c.office_id,
	      	@doc_dt		= c.create_dt
	FROM	(VALUES(@cancellation_id))v(cancellation_id)   
			LEFT JOIN	Warehouse.Cancellation c
				ON	c.cancellation_id = v.cancellation_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	SELECT	@error_text = 'ШК '
	      	+ STUFF(
	      		(
	      			SELECT	', ' + CAST(csr.shkrm_id AS VARCHAR(10)) + CHAR(10)
	      			FROM	Warehouse.CancellationShkRM csr   
	      					INNER JOIN	Warehouse.SHKRawMaterialAmount sma
	      						ON	sma.shkrm_id = csr.shkrm_id
	      					INNER JOIN Warehouse.SHKRawMaterialInfo smi
	      						ON smi.shkrm_id = sma.shkrm_id
	      			WHERE	csr.cancellation_id = @cancellation_id
	      					AND	(sma.final_dt IS NULL OR sma.amount = 0)
	      					AND smi.doc_type_id = 1
	      			FOR XML	PATH('')
	      		),
	      		1,
	      		2,
	      		''
	      	) + ' не имеют конечной стоимости.'
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	--	;
	--WITH cte AS
	--	(
	--		SELECT	rmt.rmt_id,
	--				rmt.rmt_pid,
	--				rmt.rmt_id root_rmt_id
	--		FROM	Material.RawMaterialType rmt
	--		WHERE	rmt.rmt_pid IS NULL 
	--		UNION ALL
	--		SELECT	rmt.rmt_id,
	--				rmt.rmt_pid,
	--				c.root_rmt_id root_rmt_id
	--		FROM	Material.RawMaterialType rmt   
	--				INNER JOIN	cte c
	--					ON	c.rmt_id = rmt.rmt_pid
	--	)
	--INSERT INTO @upload_buh_detail
	--	(
	--		rmt_id,
	--		nds,
	--		amount
	--	)
	--SELECT	c.root_rmt_id,
	--		smi.nds,
	--		SUM(cis.stor_unit_residues_qty * (sma.amount / sma.stor_unit_residues_qty)) amount
	--FROM	cte c   
	--		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	--			ON	smi.rmt_id = c.rmt_id   
	--		INNER JOIN	Warehouse.CancellationShkRM cis
	--			ON	cis.shkrm_id = smi.shkrm_id   
	--		INNER JOIN	Warehouse.SHKRawMaterialAmount sma
	--			ON	sma.shkrm_id = cis.shkrm_id
	--		INNER JOIN Suppliers.SupplierContract sc
	--			ON sc.suppliercontract_id = smi.suppliercontract_id
	--		INNER JOIN Suppliers.Supplier s
	--			ON s.supplier_id = sc.supplier_id
	--WHERE	cis.cancellation_id = @cancellation_id
	--	AND cis.doc_type_id = 1
	--	AND c.root_rmt_id != 144
	--	AND s.supplier_source_id = 1
	--GROUP BY
	--	c.root_rmt_id,
	--	smi.nds		
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Warehouse.Cancellation
		SET 	close_employee_id = @employee_id,
				close_dt = @dt
		WHERE	cancellation_id = @cancellation_id
				AND	close_dt IS NULL
		
		IF @@ROWCOUNT = 0
		BEGIN
		    RAISERROR('Документ уже закрыт', 16, 1)
		    RETURN
		END
		
		--DELETE FROM Synchro.UploadBuh_DocDetail
		--WHERE doc_id = @cancellation_id AND upload_doc_type_id = @upload_doc_type_id
		
		--INSERT INTO Synchro.UploadBuh_DocDetail
		--	(
		--		doc_id,
		--		upload_doc_type_id,
		--		rmt_id,
		--		nds,
		--		amount
		--	)
		--SELECT	@cancellation_id,
		--		@upload_doc_type_id,
		--		ubd.rmt_id,
		--		ubd.nds,
		--		ubd.amount
		--FROM	@upload_buh_detail ubd
		
		--DELETE FROM Synchro.UploadBuh_Doc
		--WHERE doc_id = @cancellation_id AND upload_doc_type_id = @upload_doc_type_id
	
		--INSERT INTO Synchro.UploadBuh_Doc
		--(
		--	doc_id,
		--	upload_doc_type_id,
		--	suppliercontract_code,
		--	supplier_id,
		--	is_deleted,
		--	office_id,
		--	doc_dt
		--)
		--VALUES
		--(
		--	@cancellation_id,
		--	@upload_doc_type_id,
		--	NULL,
		--	NULL,
		--	0,
		--	@office_id,
		--	@doc_dt
		--)
		
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