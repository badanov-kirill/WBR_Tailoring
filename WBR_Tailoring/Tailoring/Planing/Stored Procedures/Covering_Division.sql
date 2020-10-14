CREATE PROCEDURE [Planing].[Covering_Division]
	@spcv_xml XML,
	@employee_id INT,
	@shkrm_xml XML
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_tab TABLE (spcv_id INT)
	DECLARE @shkrm_tab TABLE (shkrm_id INT)
	DECLARE @covering_out TABLE (covering_id INT PRIMARY KEY CLUSTERED)
	
	DECLARE @base_covering_id INT
	DECLARE @office_id INT
	DECLARE @covering_reserv TABLE (cr_id INT, shkrm_id INT, qty DECIMAL(9, 3))
	DECLARE @covering_shkrm_issue TABLE (
	        	shkrm_id INT,
	        	become_return_qty DECIMAL(9, 3),
	        	was_return_qty DECIMAL(9, 3),
	        	become_return_stor_unit_residues_qty DECIMAL(9, 3),
	        	was_return_stor_unit_residues_qty DECIMAL(9, 3)
	)
	DECLARE @cisr_tab TABLE (cisr_id INT)
	
		
	INSERT INTO @spcv_tab
		(
			spcv_id
		)
	SELECT	ml.value('@spcv', 'int')
	FROM	@spcv_xml.nodes('root/det')x(ml)
	
	IF NOT EXISTS (SELECT 1 FROM @spcv_tab st) 
	BEGIN
		RAISERROR('Не передано ни одного цветоварианта',16,1)
		RETURN
	END
	
	INSERT INTO @shkrm_tab
		(
			shkrm_id
		)
	SELECT	ml.value('@shkrm', 'int')
	FROM	@shkrm_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND spcv.pan_id IS NULL THEN 'Артикул ' + s.sa + ' не связан с кодом сайта'
	      	                   WHEN oa.cnt > 1 THEN 'Цветоварианта с кодом ' + CAST(dt.spcv_id AS VARCHAR(10)) + ' указан более одного раза'
	      	                   WHEN cd.covering_id IS NULL THEN 'Цветовариант ' + spcv.spcv_name + ' артикула ' + s.sa + 
	      	                        ' отсутствует в выдаче, его неоткуда переносить'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id
				ON	spcv.spcv_id = dt.spcv_id   
			LEFT JOIN	Planing.CoveringDetail cd   
			INNER JOIN	Planing.Covering c
				ON	c.covering_id = cd.covering_id
				ON	cd.spcv_id = spcv.spcv_id   
			OUTER APPLY (
			      	SELECT	COUNT(dt2.spcv_id) cnt
			      	FROM	@spcv_tab dt2
			      	WHERE	dt2.spcv_id = dt.spcv_id
			      ) oa
	WHERE	spcv.spcv_id IS NULL
			OR	oa.cnt > 1
			OR	spcv.pan_id IS NULL
			OR	cd.covering_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF (
	   	SELECT	COUNT(DISTINCT cd.covering_id)
	   	FROM	@spcv_tab dt   
	   			INNER JOIN	Planing.CoveringDetail cd
	   				ON	cd.spcv_id = dt.spcv_id
	   ) > 1
	BEGIN
	    RAISERROR('Выбраны цветоварианты из нескольких выдач', 16, 1)
	    RETURN
	END
	
	SELECT	@base_covering_id = cd.covering_id,
			@office_id = c.office_id
	FROM	@spcv_tab dt   
			INNER JOIN	Planing.CoveringDetail cd   
			INNER JOIN	Planing.Covering c
				ON	c.covering_id = cd.covering_id
				ON	cd.spcv_id = dt.spcv_id   
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.spcvts_id IS NULL THEN 'Цветовариант ' + spcv.spcv_name + ' артикула ' + s.sa + ' нет в плане раскроя'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab dt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = dt.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = dt.spcv_id
				AND	spcvt.cnt > 0   
			LEFT JOIN	Manufactory.Cutting c
				ON	c.spcvts_id = spcvt.spcvts_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	
	INSERT INTO @covering_reserv
		(
			cr_id,
			shkrm_id,
			qty
		)
	SELECT	cr.cr_id,
			cr.shkrm_id,
			cr.qty
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = st.spcv_id   
			INNER JOIN	Planing.CoveringReserv cr
				ON	cr.spcvc_id = spcvc.spcvc_id
	WHERE cr.covering_id = @base_covering_id
	
	INSERT INTO @cisr_tab
		(
			cisr_id
		)
	SELECT	MAX(cis.cisr_id)
	FROM	Planing.CoveringIssueSHKRm cis
	WHERE	cis.covering_id = @base_covering_id
	GROUP BY
		cis.covering_id,
		cis.shkrm_id
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Planing.Covering
			(
				create_dt,
				create_employee_id,
				office_id
			)OUTPUT	INSERTED.covering_id
			 INTO	@covering_out (
			 		covering_id
			 	)
		VALUES
			(
				@dt,
				@employee_id,
				@office_id
			)
		

		
		UPDATE	cis
		SET 	covering_id = co.covering_id
		FROM	Planing.CoveringIssueSHKRm cis
				INNER JOIN	@cisr_tab ct
					ON	ct.cisr_id = cis.cisr_id
				CROSS JOIN	@covering_out co
				OUTER APPLY (
				      	SELECT	SUM(cr.qty) qty
				      	FROM	@covering_reserv cr
				      	WHERE	cr.shkrm_id = cis.shkrm_id
				      ) reserv_div
		OUTER APPLY (
		      	SELECT	SUM(cr2.qty) qty
		      	FROM	Planing.CoveringReserv cr2
		      	WHERE	cr2.shkrm_id = cis.shkrm_id
		      			AND	cr2.covering_id = cis.covering_id
		      ) reserv_all
		WHERE	cis.covering_id = @base_covering_id
				AND	(
				   		reserv_div.qty = reserv_all.qty
				   		OR cis.qty - cis.return_qty <= reserv_div.qty
				   		OR EXISTS (
				   		   	SELECT	1
				   		   	FROM	@shkrm_tab srmt
				   		   	WHERE	srmt.shkrm_id = cis.shkrm_id
				   		   )
				   	)
		
		UPDATE	cis
		SET 	return_qty = reserv_div.qty + cis.return_qty,
				return_stor_unit_residues_qty = reserv_div.qty * cis.stor_unit_residues_qty / cis.qty + cis.return_stor_unit_residues_qty
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.return_qty,
						DELETED.return_qty,
						INSERTED.return_stor_unit_residues_qty,
						DELETED.return_stor_unit_residues_qty						
				INTO	@covering_shkrm_issue (
						shkrm_id,
						become_return_qty,
						was_return_qty,
						become_return_stor_unit_residues_qty,
						was_return_stor_unit_residues_qty
					)
		FROM	Planing.CoveringIssueSHKRm cis
				INNER JOIN	@cisr_tab ct
					ON	ct.cisr_id = cis.cisr_id
				OUTER APPLY (
				      	SELECT	SUM(cr.qty) qty
				      	FROM	@covering_reserv cr
				      	WHERE	cr.shkrm_id = cis.shkrm_id
				      ) reserv_div
		WHERE	cis.covering_id = @base_covering_id
				AND	cis.return_qty IS NOT NULL
				AND	ISNULL(reserv_div.qty, 0) > 0
				AND	cis.qty != cis.return_qty
				AND	cis.qty - cis.return_qty > reserv_div.qty				
		
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
		SELECT	co.covering_id,
				csi.shkrm_id,
				cis.okei_id,
				csi.become_return_qty,
				cis.stor_unit_residues_okei_id,
				csi.become_return_stor_unit_residues_qty,
				cis.dt,
				cis.employee_id,
				cis.recive_employee_id,
				csi.was_return_qty,
				csi.was_return_stor_unit_residues_qty,
				cis.return_dt,
				cis.return_employee_id,
				cis.return_recive_employee_id
		FROM	@covering_shkrm_issue csi   
				INNER JOIN	Planing.CoveringIssueSHKRm cis
					ON	cis.shkrm_id = csi.shkrm_id  AND cis.covering_id = @base_covering_id  
				CROSS JOIN	@covering_out co 
		
		UPDATE	cd
		SET 	covering_id = co.covering_id
		FROM	Planing.CoveringDetail cd
				INNER JOIN	@spcv_tab st
					ON	st.spcv_id = cd.spcv_id
				CROSS JOIN	@covering_out co 
		
		UPDATE	cr
		SET 	covering_id = co.covering_id
		FROM	Planing.CoveringReserv cr
				INNER JOIN	@covering_reserv cor
					ON	cor.cr_id = cr.cr_id
				CROSS JOIN	@covering_out co 
		
		COMMIT TRANSACTION
		
		SELECT	c.covering_id,
				CAST(@dt AS DATETIME)     dt
		FROM	@covering_out             c
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
	