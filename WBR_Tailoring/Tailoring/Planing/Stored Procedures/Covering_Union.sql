CREATE PROCEDURE [Planing].[Covering_Union]
	@covering_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @covering_tab TABLE (covering_id INT)
	DECLARE @recipient_covering_id INT
	DECLARE @covering_detail_out TABLE (spcv_id INT, is_deleted BIT)
	
	DECLARE @covering_issue_shkrm_out TABLE (
	        	shkrm_id INT,
	        	okei_id INT,
	        	qty DECIMAL(9, 3),
	        	stor_unit_residues_okei_id INT,
	        	stor_unit_residues_qty DECIMAL(9, 3),
	        	recive_employee_id INT,
	        	return_qty DECIMAL(9, 3),
	        	return_stor_unit_residues_qty DECIMAL(9, 3),
	        	return_dt DATETIME2(0),
	        	return_employee_id INT,
	        	return_recive_employee_id INT
	        )
	
	DECLARE @covering_reserv_out TABLE (spcvc_id INT, shkrm_id INT, okei_id INT, qty DECIMAL(9, 3), pre_cost DECIMAL(9,2))
	
	INSERT INTO @covering_tab
		(
			covering_id
		)
	SELECT	ml.value('@cov', 'int')
	FROM	@covering_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NOT NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' уже закрыта.'
	      	                   ELSE NULL
	      	              END
	FROM	@covering_tab v   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id
	WHERE	c.covering_id IS NULL
			OR	c.close_dt IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN vt.cnt_office > 1 THEN 'Объединяемые выдачи должны быть из одного офиса'
	      	                   WHEN vt.cnt_covering < 2 THEN 'Объединяемых выдач должно быть больше одной'
	      	                   ELSE NULL
	      	              END,
			@recipient_covering_id = vt.max_covering_id
	FROM	(SELECT	COUNT(DISTINCT c.office_id) cnt_office,
	    	 		COUNT(DISTINCT c.covering_id) cnt_covering,
	    	 		MAX(c.covering_id) max_covering_id
	    	 FROM	@covering_tab v   
	    	 		INNER JOIN	Planing.Covering c
	    	 			ON	c.covering_id = v.covering_id)vt
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	cd
		      	OUTPUT	DELETED.spcv_id,
		      			DELETED.is_deleted
		      	INTO	@covering_detail_out (
		      			spcv_id,
		      			is_deleted
		      		)
		FROM	Planing.CoveringDetail cd
		WHERE	cd.covering_id != @recipient_covering_id
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@covering_tab ct
				   		WHERE	cd.covering_id = ct.covering_id
				   	)
		
		INSERT INTO Planing.CoveringDetail
			(
				covering_id,
				spcv_id,
				dt,
				employee_id,
				is_deleted
			)
		SELECT	@recipient_covering_id,
				cdo.spcv_id,
				@dt,
				@employee_id,
				cdo.is_deleted
		FROM	@covering_detail_out cdo
		
		DELETE	cis
		      	OUTPUT	DELETED.shkrm_id,
		      			DELETED.okei_id,
		      			DELETED.qty,
		      			DELETED.stor_unit_residues_okei_id,
		      			DELETED.stor_unit_residues_qty,
		      			DELETED.recive_employee_id,
		      			DELETED.return_qty,
		      			DELETED.return_stor_unit_residues_qty,
		      			DELETED.return_dt,
		      			DELETED.return_employee_id,
		      			DELETED.return_recive_employee_id
		      	INTO	@covering_issue_shkrm_out (
		      			shkrm_id,
		      			okei_id,
		      			qty,
		      			stor_unit_residues_okei_id,
		      			stor_unit_residues_qty,
		      			recive_employee_id,
		      			return_qty,
		      			return_stor_unit_residues_qty,
		      			return_dt,
		      			return_employee_id,
		      			return_recive_employee_id
		      		)
		FROM	Planing.CoveringIssueSHKRm cis
		WHERE	cis.covering_id != @recipient_covering_id
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@covering_tab ct
				   		WHERE	cis.covering_id = ct.covering_id
				   	)
		
		INSERT INTO Planing.CoveringIssueSHKRm
			(
				covering_id,
				shkrm_id,
				okei_id,
				qty,
				stor_unit_residues_okei_id,
				stor_unit_residues_qty,
				dt,
				employee_id,
				recive_employee_id,
				return_qty,
				return_stor_unit_residues_qty,
				return_dt,
				return_employee_id,
				return_recive_employee_id
			)
		SELECT	@recipient_covering_id,
				ciso.shkrm_id,
				ciso.okei_id,
				ciso.qty,
				ciso.stor_unit_residues_okei_id,
				ciso.stor_unit_residues_qty,
				@dt,
				@employee_id,
				ciso.recive_employee_id,
				ciso.return_qty,
				ciso.return_stor_unit_residues_qty,
				ciso.return_dt,
				ciso.return_employee_id,
				ciso.return_recive_employee_id
		FROM	@covering_issue_shkrm_out ciso
		
		DELETE	cr
		      	OUTPUT	DELETED.spcvc_id,
		      			DELETED.shkrm_id,
		      			DELETED.okei_id,
		      			DELETED.qty,
		      			DELETED.pre_cost
		      	INTO	@covering_reserv_out (
		      			spcvc_id,
		      			shkrm_id,
		      			okei_id,
		      			qty,
		      			pre_cost
		      		)
		FROM	Planing.CoveringReserv cr
		WHERE	cr.covering_id != @recipient_covering_id
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@covering_tab ct
				   		WHERE	cr.covering_id = ct.covering_id
				   	)
		
		INSERT INTO Planing.CoveringReserv
			(
				covering_id,
				spcvc_id,
				shkrm_id,
				okei_id,
				qty,
				dt,
				employee_id,
				pre_cost
			)
		SELECT	@recipient_covering_id,
				cro.spcvc_id,
				cro.shkrm_id,
				cro.okei_id,
				cro.qty,
				@dt,
				@employee_id,
				cro.pre_cost
		FROM	@covering_reserv_out cro 
		
		DELETE	c
		FROM	Planing.Covering c
		WHERE	c.covering_id != @recipient_covering_id
				AND	EXISTS(
				   		SELECT	1
				   		FROM	@covering_tab ct
				   		WHERE	c.covering_id = ct.covering_id
				   	)
		
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
	