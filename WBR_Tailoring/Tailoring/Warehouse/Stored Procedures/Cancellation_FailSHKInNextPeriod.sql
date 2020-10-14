CREATE PROCEDURE [Warehouse].[Cancellation_FailSHKInNextPeriod]
	@cancellation_id INT,
	@employee_id INT,
	@shkrm_xml XML
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @office_id INT
	DECLARE @cancellation_year SMALLINT
	DECLARE @cancellation_month TINYINT
	DECLARE @new_cancellation_id INT
	DECLARE @cancellation_out TABLE (cancellation_id INT)
	DECLARE @cancellation_shk_out TABLE (
	        	shkrm_id INT,
	        	doc_id INT,
	        	doc_type_id TINYINT,
	        	rmt_id INT,
	        	art_id INT,
	        	color_id INT,
	        	su_id INT,
	        	suppliercontract_id INT,
	        	okei_id INT,
	        	qty DECIMAL(9, 3),
	        	stor_unit_residues_okei_id INT,
	        	stor_unit_residues_qty DECIMAL(9, 3),
	        	nds TINYINT,
	        	dt dbo.SECONDSTIME,
	        	employee_id INT,
	        	is_deleted BIT,
	        	frame_width SMALLINT,
	        	is_defected BIT
	        )
	
	
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id
		)
	SELECT	ml.value('@shkrm[1]', 'int')
	FROM	@shkrm_xml.nodes('root/det')x(ml)   
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.cancellation_id IS NULL THEN 'Документа списания с номером ' + CAST(v.cancellation_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Документ уже закрыт.'
	      	                   ELSE NULL
	      	              END,
			@office_id              = c.office_id,
			@cancellation_year      = YEAR(DATEADD(MONTH, 1, DATEFROMPARTS(c.cancellation_year, c.cancellation_month, 1))),
			@cancellation_month     = MONTH(DATEADD(MONTH, 1, DATEFROMPARTS(c.cancellation_year, c.cancellation_month, 1)))
	FROM	(VALUES(@cancellation_id))v(cancellation_id)   
			LEFT JOIN	Warehouse.Cancellation c
				ON	c.cancellation_id = v.cancellation_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN dt.shkrm_id IS NULL THEN 'Некорректный XML. Обратитесь к разработчику.'
	      	                   WHEN dt.shkrm_id IS NOT NULL AND sm.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) + ' не существует.'	      	                   
	      	                   WHEN sm.shkrm_id IS NOT NULL AND csr.shkrm_id IS NULL THEN 'ШК ' + CAST(dt.shkrm_id AS VARCHAR(10)) +
	      	                        ' отсутствует в списании № ' + CAST(@cancellation_id AS VARCHAR(10)) 
	      	                        + ' обратитесь к разработчику.'
	      	                   ELSE NULL
	      	              END
	FROM	@shkrm_tab dt   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = dt.shkrm_id   			
			LEFT JOIN	Warehouse.CancellationShkRM csr
				ON	csr.shkrm_id = dt.shkrm_id
				AND	csr.cancellation_id = @cancellation_id
	WHERE	dt.shkrm_id IS NULL
			OR	sm.shkrm_id IS NULL
			OR	csr.shkrm_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Списание в следующем периоде уже закрыто. Переносить ШК нельзя.'
	      	                   ELSE NULL
	      	              END,
			@new_cancellation_id = c.cancellation_id
	FROM	Warehouse.Cancellation c
	WHERE	c.office_id = @office_id
			AND	c.cancellation_year = @cancellation_year
			AND	c.cancellation_month = @cancellation_month
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		IF @new_cancellation_id IS NULL
		BEGIN
		    INSERT INTO Warehouse.Cancellation
		    	(
		    		create_dt,
		    		create_employee_id,
		    		office_id,
		    		cancellation_year,
		    		cancellation_month,
		    		close_employee_id,
		    		close_dt
		    	)OUTPUT	INSERTED.cancellation_id
		    	 INTO	@cancellation_out (
		    	 		cancellation_id
		    	 	)
		    VALUES
		    	(
		    		@dt,
		    		@employee_id,
		    		@office_id,
		    		@cancellation_year,
		    		@cancellation_month,
		    		NULL,
		    		NULL
		    	)
		    
		    SELECT	@new_cancellation_id = co.cancellation_id
		    FROM	@cancellation_out co
		END
		
		DELETE	csr 
		      	OUTPUT	DELETED.shkrm_id,
		      			DELETED.doc_id,
		      			DELETED.doc_type_id,
		      			DELETED.rmt_id,
		      			DELETED.art_id,
		      			DELETED.color_id,
		      			DELETED.su_id,
		      			DELETED.suppliercontract_id,
		      			DELETED.okei_id,
		      			DELETED.qty,
		      			DELETED.stor_unit_residues_okei_id,
		      			DELETED.stor_unit_residues_qty,
		      			DELETED.nds,
		      			DELETED.dt,
		      			DELETED.employee_id,
		      			DELETED.is_deleted,
		      			DELETED.frame_width,
		      			DELETED.is_defected
		      	INTO	@cancellation_shk_out (
		      			shkrm_id,
		      			doc_id,
		      			doc_type_id,
		      			rmt_id,
		      			art_id,
		      			color_id,
		      			su_id,
		      			suppliercontract_id,
		      			okei_id,
		      			qty,
		      			stor_unit_residues_okei_id,
		      			stor_unit_residues_qty,
		      			nds,
		      			dt,
		      			employee_id,
		      			is_deleted,
		      			frame_width,
		      			is_defected		      			
		      		)
		FROM	Warehouse.CancellationShkRM csr   
				INNER JOIN	@shkrm_tab st
					ON	st.shkrm_id = csr.shkrm_id
		WHERE	csr.cancellation_id = @cancellation_id
		
		INSERT INTO Warehouse.CancellationShkRM
			(
				cancellation_id,
				shkrm_id,
				doc_id,
				doc_type_id,
				rmt_id,
				art_id,
				color_id,
				su_id,
				suppliercontract_id,
				okei_id,
				qty,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				nds,
				dt,
				employee_id,
				is_deleted,
				frame_width,
				is_defected
			)
		SELECT	@new_cancellation_id,
				cso.shkrm_id,
				cso.doc_id,
				cso.doc_type_id,
				cso.rmt_id,
				cso.art_id,
				cso.color_id,
				cso.su_id,
				cso.suppliercontract_id,
				cso.okei_id,
				cso.qty,
				cso.stor_unit_residues_okei_id,
				cso.stor_unit_residues_qty,
				cso.nds,
				cso.dt,
				cso.employee_id,
				cso.is_deleted,
				cso.frame_width,
				cso.is_defected
		FROM	@cancellation_shk_out cso
		
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