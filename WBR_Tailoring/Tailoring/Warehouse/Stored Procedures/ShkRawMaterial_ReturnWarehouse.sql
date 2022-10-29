CREATE PROCEDURE [Warehouse].[SHKRawMaterial_ReturnWarehouse]
	@shkrm_id INT,
	@employee_id INT,
	@return_employee_id INT,
	@retyrn_qty DECIMAL(9, 3),
	@place_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @shkrm_state_dst INT = 9
	DECLARE @shkrm_state_dst2 INT = 3
	DECLARE @proc_id INT
	DECLARE @return_stor_unit_residues_qty DECIMAL(9, 3)
	DECLARE @retyrn_gross_mass INT
	DECLARE @mip_id INT
	DECLARE @mipds_id INT
	DECLARE @spcvc_tab TABLE (spcvc_id INT PRIMARY KEY CLUSTERED)
	DECLARE @covering_id INT
	DECLARE @cisr_id INT
	DECLARE @mis_id INT
	DECLARE @upload_doc_type_id TINYINT
	DECLARE @is_terminal_residues BIT = 0
	
	
	IF @retyrn_qty != 0
	   AND @place_id IS NULL
	BEGIN
	    RAISERROR('Не уазано место хранения', 16, 1)
	    RETURN
	END
	
	IF @place_id IS NOT NULL
	   AND NOT EXISTS(
	       	SELECT	1
	       	FROM	Warehouse.StoragePlace sp
	       	WHERE	sp.place_id = @place_id
	       )
	BEGIN
	    RAISERROR('МХ с кодом %d не существует.', 16, 1, @place_id)
	    RETURN
	END
	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Нет описания ШК. Обратитесь к разработчику'
	      	                   --WHEN mipds.rmt_id != smai.rmt_id OR mipds.art_id != smai.art_id OR mipds.qty != smai.qty OR mipds.okei_id 
	      	                   --     != smai.okei_id THEN 'По этому ШК ' + CAST(mipds.shkrm_id AS VARCHAR(10)) +
	      	                   --     ' не совтадают данные выдачи и текущие данные по шк. Обратитесь к разработчику' + CHAR(10) +
	      	                   --     'Кол-во ' + CAST(smai.qty AS VARCHAR(10)) + ' и ' + CAST(mipds.qty AS VARCHAR(10)) + CHAR(10) +
	      	                   --     'ОКЕИ ' + CAST(smai.okei_id AS VARCHAR(10)) + ' и ' + CAST(mipds.okei_id AS VARCHAR(10)) + CHAR(10) +
	      	                   --     'Код типа ' + CAST(smai.rmt_id AS VARCHAR(10)) + ' и ' + CAST(mipds.art_id AS VARCHAR(10)) + CHAR(10) +
	      	                   --     'Код артикула' + + CAST(smai.art_id AS VARCHAR(10)) + ' и ' + CAST(mipds.art_id AS VARCHAR(10))
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(mipds.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(mipds.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN smai.qty < @retyrn_qty THEN 'Нельзя вернуть больше чем выдавалось'
	      	                   ELSE NULL
	      	              END,
			@return_stor_unit_residues_qty = @retyrn_qty * mipds.stor_unit_residues_qty / mipds.qty,
			@mip_id = mipds.mip_id,
			@retyrn_gross_mass = smai.gross_mass * @retyrn_qty / smai.qty,
			@mipds_id = mipds.mipds_id,
			@is_terminal_residues = CASE 
			                             WHEN @retyrn_qty = 0 THEN 0
			                             WHEN rmttr.rmt_id IS NOT NULL AND rmttr.stor_unit_residues_qty >= (@retyrn_qty * mipds.stor_unit_residues_qty / mipds.qty) THEN 1
			                             ELSE 0
			                        END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			INNER JOIN	Warehouse.MaterialInProductionDetailShk mipds   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = mipds.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = mipds.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mipds.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sms.shkrm_id = mipds.shkrm_id
				ON	mipds.shkrm_id = v.shkrm_id
				AND	mipds.return_dt IS NULL   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst   
			LEFT JOIN Material.RawMaterialTypeTerminalResidues rmttr
				ON rmttr.rmt_id = smai.rmt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Нет описания ШК. Обратитесь к разработчику'
	      	                   WHEN cis.qty != smai.qty OR cis.okei_id != smai.okei_id THEN 'По этому ШК ' + CAST(cis.shkrm_id AS VARCHAR(10)) +
	      	                        ' не совтадают данные выдачи и текущие данные по шк. Обратитесь к разработчику' + CHAR(10) +
	      	                        'Кол-во ' + CAST(smai.qty AS VARCHAR(10)) + ' и ' + CAST(cis.qty AS VARCHAR(10)) + CHAR(10) +
	      	                        'ОКЕИ ' + CAST(smai.okei_id AS VARCHAR(10)) + ' и ' + CAST(cis.okei_id AS VARCHAR(10))
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(cis.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(cis.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN ISNULL(oar2.quantity, 0) > @return_stor_unit_residues_qty THEN 'Этот ШК зарезервирован ещё на: ' + CHAR(10) + ISNULL(oar.x, 'Другие артикула. ') + 'Перед списанием, необходимо скорректировать резервы. Обратитесь к руководителю.'
	      	                   WHEN smai.qty < @retyrn_qty THEN 'Нельзя вернуть больше чем выдавалось'
	      	                   ELSE NULL
	      	              END,
			@return_stor_unit_residues_qty = @retyrn_qty * cis.stor_unit_residues_qty / cis.qty,
			@retyrn_gross_mass = smai.gross_mass * @retyrn_qty / smai.qty,
			@cisr_id = cis.cisr_id,
			@covering_id = cis.covering_id,
			@is_terminal_residues = CASE 
			                             WHEN @retyrn_qty = 0 THEN 0
			                             WHEN rmttr.rmt_id IS NOT NULL AND rmttr.stor_unit_residues_qty >= (@retyrn_qty * cis.stor_unit_residues_qty / cis.qty) THEN 
			                                  1
			                             ELSE 0
			                        END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			INNER JOIN Planing.CoveringIssueSHKRm cis  
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = cis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sms.shkrm_id = cis.shkrm_id
				ON	cis.shkrm_id = v.shkrm_id
				AND	cis.return_dt IS NULL   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst 
			LEFT JOIN Material.RawMaterialTypeTerminalResidues rmttr
				ON rmttr.rmt_id = smai.rmt_id  
			OUTER APPLY (
			      	SELECT 	'' +  sj.subject_name_sf + ' - ' +an.art_name + ' (' + cast(SUM(smr.quantity) AS VARCHAR(10)) + ') ; ' + CHAR(10)
			      	FROM	Warehouse.SHKRawMaterialReserv smr   
			      			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
			      				ON	spcvc.spcvc_id = smr.spcvc_id    
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = spcvc.spcv_id   
			      			INNER JOIN	Planing.SketchPlan sp
			      				ON	sp.sp_id = spcv.sp_id   
			      			INNER JOIN	Products.Sketch s
			      				ON	s.sketch_id = sp.sketch_id   
			      			INNER JOIN	Products.ArtName an
			      				ON	an.art_name_id = s.art_name_id   
			      			INNER JOIN	Products.[Subject] sj
			      				ON	sj.subject_id = s.subject_id
			      	WHERE	smr.shkrm_id = v.shkrm_id
			      			AND	NOT EXISTS (
			      			   		SELECT	1
			      			   		FROM	Planing.CoveringReserv cr
			      			   		WHERE	cr.covering_id = cis.covering_id
			      			   				AND	cr.spcvc_id = smr.spcvc_id
			      			)
			      	GROUP BY sj.subject_name_sf ,an.art_name 
					FOR XML PATH('')
			) oar(x)
			OUTER APPLY (
			      	SELECT 	SUM(smr.quantity) quantity
			      	FROM	Warehouse.SHKRawMaterialReserv smr 			      			
			      	WHERE	smr.shkrm_id = v.shkrm_id
			      			AND	NOT EXISTS (
			      			   		SELECT	1
			      			   		FROM	Planing.CoveringReserv cr
			      			   		WHERE	cr.covering_id = cis.covering_id
			      			   				AND	cr.spcvc_id = smr.spcvc_id
			      			)
			      	
			) oar2
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Нет описания ШК. Обратитесь к разработчику'
	      	                   WHEN mis.qty != smai.qty OR mis.okei_id != smai.okei_id THEN 'По этому ШК ' + CAST(mis.shkrm_id AS VARCHAR(10)) +
	      	                        ' не совтадают данные выдачи и текущие данные по шк. Обратитесь к разработчику' + CHAR(10) +
	      	                        'Кол-во ' + CAST(smai.qty AS VARCHAR(10)) + ' и ' + CAST(mis.qty AS VARCHAR(10)) + CHAR(10) +
	      	                        'ОКЕИ ' + CAST(smai.okei_id AS VARCHAR(10)) + ' и ' + CAST(mis.okei_id AS VARCHAR(10))
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(mis.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   WHEN smsg.state_src_id IS NULL THEN 'Штрихкод ' + CAST(mis.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        '. Переход в статус ' + smsd2.state_name + ' запрещен.'
	      	                   WHEN ISNULL(oar2.quantity, 0) > @retyrn_qty THEN 'Этот ШК зарезервирован на: ' + CHAR(10) + ISNULL(oar.x, 'Другие артикула.') + 'Перед списанием, необходимо скорректировать резервы. Обратитесь к руководителю.'
	      	                   WHEN smai.qty < @retyrn_qty THEN 'Нельзя вернуть больше чем выдавалось'
	      	                   ELSE NULL
	      	              END,
			@return_stor_unit_residues_qty = @retyrn_qty * mis.stor_unit_residues_qty / mis.qty,
			@retyrn_gross_mass = smai.gross_mass * @retyrn_qty / smai.qty,
			@mis_id = mis.mis_id,
			@is_terminal_residues = CASE 
			                             WHEN @retyrn_qty = 0 THEN 0
			                             WHEN rmttr.rmt_id IS NOT NULL AND rmttr.stor_unit_residues_qty >= (@retyrn_qty * mis.stor_unit_residues_qty / mis.qty) THEN 
			                                  1
			                             ELSE 0
			                        END
	FROM (VALUES(@shkrm_id))v(shkrm_id)   
			INNER JOIN Warehouse.MaterialInSketch mis  
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = mis.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smai.okei_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id   
			LEFT JOIN	Warehouse.SHKRawMaterialStateGraph smsg
				ON	sms.state_id = smsg.state_src_id
				AND	smsg.state_dst_id = @shkrm_state_dst
				ON	sms.shkrm_id = mis.shkrm_id
				ON	mis.shkrm_id = v.shkrm_id
				AND	mis.return_dt IS NULL   
			LEFT  JOIN	Warehouse.SHKRawMaterialStateDict smsd2
				ON	smsd2.state_id = @shkrm_state_dst 
			LEFT JOIN Material.RawMaterialTypeTerminalResidues rmttr
				ON rmttr.rmt_id = smai.rmt_id
			OUTER APPLY (
			      	SELECT 	'' +  sj.subject_name_sf + ' - ' +an.art_name + ' (' + cast(SUM(smr.quantity) AS VARCHAR(10)) + ') ; ' + CHAR(10)
			      	FROM	Warehouse.SHKRawMaterialReserv smr   
			      			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
			      				ON	spcvc.spcvc_id = smr.spcvc_id    
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = spcvc.spcv_id   
			      			INNER JOIN	Planing.SketchPlan sp
			      				ON	sp.sp_id = spcv.sp_id   
			      			INNER JOIN	Products.Sketch s
			      				ON	s.sketch_id = sp.sketch_id   
			      			INNER JOIN	Products.ArtName an
			      				ON	an.art_name_id = s.art_name_id   
			      			INNER JOIN	Products.[Subject] sj
			      				ON	sj.subject_id = s.subject_id
			      	WHERE	smr.shkrm_id = v.shkrm_id
			      	GROUP BY sj.subject_name_sf ,an.art_name 
					FOR XML PATH('')
			) oar(x)
			OUTER APPLY (
			      	SELECT 	SUM(smr.quantity) quantity
			      	FROM	Warehouse.SHKRawMaterialReserv smr 			      			
			      	WHERE	smr.shkrm_id = v.shkrm_id			      			
			) oar2
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @mipds_id IS NULL
	   AND @cisr_id IS NULL
	   AND @mis_id IS NULL
	BEGIN
	    RAISERROR('ШК %d не найден в выданных и не возвращенных материалах.', 16, 1, @shkrm_id)
	    RETURN
	END
	
	IF (@mis_id IS NOT NULL AND (@mipds_id IS NOT NULL OR @cisr_id IS NOT NULL)) OR
	(@cisr_id IS NOT NULL AND (@mipds_id IS NOT NULL OR @mis_id IS NOT NULL)) OR
	(@mipds_id IS NOT NULL AND (@cisr_id IS NOT NULL OR @mis_id IS NOT NULL)) 
	BEGIN
		RAISERROR('ШК %d выдан в нескольких документах, обратитесь к разработчику.',16,1,@shkrm_id)
		RETURN
	END
	
	
	INSERT INTO @spcvc_tab
		(
			spcvc_id
		)
	SELECT	DISTINCT cr.spcvc_id
	FROM	Planing.CoveringReserv cr
	WHERE	cr.covering_id = @covering_id	
		
	BEGIN TRY
		BEGIN TRANSACTION		
		
		IF EXISTS(
		   	SELECT	1
		   	FROM	@spcvc_tab
		   )
		BEGIN
		    DELETE	sr
		          	OUTPUT	DELETED.shkrm_id,
		          			DELETED.spcvc_id,
		          			DELETED.okei_id,
		          			DELETED.quantity,
		          			@dt,
		          			@employee_id,
		          			DELETED.rmid_id,
		          			DELETED.rmodr_id,
		          			@proc_id,
		          			'D'
		          	INTO	History.SHKRawMaterialReserv (
		          			shkrm_id,
		          			spcvc_id,
		          			okei_id,
		          			quantity,
		          			dt,
		          			employee_id,
		          			rmid_id,
		          			rmodr_id,
		          			proc_id,
		          			operation
		          		)
		    FROM	Warehouse.SHKRawMaterialReserv sr   
		    		INNER JOIN	@spcvc_tab st
		    			ON	st.spcvc_id = sr.spcvc_id
		    WHERE	sr.shkrm_id = @shkrm_id
		END
		ELSE
		BEGIN
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialReserv
		        	OUTPUT	DELETED.shkrm_id,
		        			DELETED.spcvc_id,
		        			DELETED.okei_id,
		        			DELETED.quantity,
		        			@dt,
		        			@employee_id,
		        			DELETED.rmid_id,
		        			DELETED.rmodr_id,
		        			@proc_id,
		        			'D'
		        	INTO	History.SHKRawMaterialReserv (
		        			shkrm_id,
		        			spcvc_id,
		        			okei_id,
		        			quantity,
		        			dt,
		        			employee_id,
		        			rmid_id,
		        			rmodr_id,
		        			proc_id,
		        			operation
		        		)
		    WHERE	shkrm_id = @shkrm_id
		END;
		
		IF @retyrn_qty = 0
		BEGIN
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialActualInfo
		        	OUTPUT	DELETED.shkrm_id,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialActualInfo (
		        			shkrm_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialDefectDescr
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialDefectDescr (
		        			shkrm_id,
		        			descr,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialState
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialState (
		        			shkrm_id,
		        			state_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		    
		    DELETE	
		    FROM	Warehouse.SHKRawMaterialOnPlace
		        	OUTPUT	DELETED.shkrm_id,
		        			NULL,
		        			@dt,
		        			@employee_id,
		        			@proc_id
		        	INTO	History.SHKRawMaterialOnPlace (
		        			shkrm_id,
		        			place_id,
		        			dt,
		        			employee_id,
		        			proc_id
		        		)
		    WHERE	shkrm_id = @shkrm_id
		END
		ELSE
		BEGIN
		    UPDATE	Warehouse.SHKRawMaterialActualInfo
		    SET 	qty = @retyrn_qty,
		    		stor_unit_residues_qty = @return_stor_unit_residues_qty,
		    		gross_mass = @retyrn_gross_mass,
		    		dt = @dt,
		    		employee_id = @employee_id,
		    		is_terminal_residues = @is_terminal_residues
		    		OUTPUT	INSERTED.shkrm_id,
		    				INSERTED.doc_id,
		    				INSERTED.doc_type_id,
		    				INSERTED.suppliercontract_id,
		    				INSERTED.rmt_id,
		    				INSERTED.art_id,
		    				INSERTED.color_id,
		    				INSERTED.su_id,
		    				INSERTED.okei_id,
		    				INSERTED.qty,
		    				INSERTED.stor_unit_residues_okei_id,
		    				INSERTED.stor_unit_residues_qty,
		    				INSERTED.dt,
		    				INSERTED.employee_id,
		    				INSERTED.frame_width,
		    				INSERTED.is_defected,
		    				INSERTED.is_deleted,
		    				@proc_id,
		    				INSERTED.nds,
		    				INSERTED.gross_mass,
		    				INSERTED.is_terminal_residues,
		    				INSERTED.tissue_density
		    		INTO	History.SHKRawMaterialActualInfo (
		    				shkrm_id,
		    				doc_id,
		    				doc_type_id,
		    				suppliercontract_id,
		    				rmt_id,
		    				art_id,
		    				color_id,
		    				su_id,
		    				okei_id,
		    				qty,
		    				stor_unit_residues_okei_id,
		    				stor_unit_residues_qty,
		    				dt,
		    				employee_id,
		    				frame_width,
		    				is_defected,
		    				is_deleted,
		    				proc_id,
		    				nds,
		    				gross_mass,
		    				is_terminal_residues,
		    				tissue_density
		    			)
		    WHERE	shkrm_id = @shkrm_id
		    
		    UPDATE	s
		    SET 	state_id = @shkrm_state_dst,
		    		dt = @dt,
		    		employee_id = @employee_id
		    		OUTPUT	INSERTED.shkrm_id,
		    				INSERTED.state_id,
		    				INSERTED.dt,
		    				INSERTED.employee_id,
		    				@proc_id
		    		INTO	History.SHKRawMaterialState (
		    				shkrm_id,
		    				state_id,
		    				dt,
		    				employee_id,
		    				proc_id
		    			)
		    FROM	Warehouse.SHKRawMaterialState s
		    		INNER JOIN	Warehouse.SHKRawMaterialStateGraph smsg
		    			ON	s.state_id = smsg.state_src_id
		    			AND	smsg.state_dst_id = @shkrm_state_dst
		    WHERE	s.shkrm_id = @shkrm_id
		    
		    IF @@ROWCOUNT = 0
		    BEGIN
		        SET @with_log = 0
		        RAISERROR('Операция со штрихкодом %d запрещена', 16, 1, @shkrm_id);
		        RETURN
		    END 
		    ;
		    
		    UPDATE	s
		    SET 	state_id = @shkrm_state_dst2,
		    		dt = @dt,
		    		employee_id = @employee_id
		    		OUTPUT	INSERTED.shkrm_id,
		    				INSERTED.state_id,
		    				INSERTED.dt,
		    				INSERTED.employee_id,
		    				@proc_id
		    		INTO	History.SHKRawMaterialState (
		    				shkrm_id,
		    				state_id,
		    				dt,
		    				employee_id,
		    				proc_id
		    			)
		    FROM	Warehouse.SHKRawMaterialState s		    		
		    WHERE	s.shkrm_id = @shkrm_id
		    
		    MERGE Warehouse.SHKRawMaterialOnPlace t
		    USING (
		          	SELECT	@shkrm_id shkrm_id
		          ) s
		    		ON t.shkrm_id = s.shkrm_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	t.place_id = @place_id,
		         		t.dt = @dt,
		         		t.employee_id = @employee_id
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		shkrm_id,
		         		place_id,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.shkrm_id,
		         		@place_id,
		         		@dt,
		         		@employee_id
		         	)
		         OUTPUT	INSERTED.shkrm_id,
		         		INSERTED.place_id,
		         		INSERTED.dt,
		         		INSERTED.employee_id,
		         		@proc_id
		         INTO	History.SHKRawMaterialOnPlace (
		         		shkrm_id,
		         		place_id,
		         		dt,
		         		employee_id,
		         		proc_id
		         	);
		END
		
		IF @mipds_id IS NOT NULL 
		BEGIN
			UPDATE	Warehouse.MaterialInProductionDetailShk
			SET 	return_qty = @retyrn_qty,
					return_dt = @dt,
					return_employee_id = @return_employee_id,
					return_recive_employee_id = @employee_id
			WHERE	mipds_id = @mipds_id
					AND	return_dt IS NULL
		END
		
		IF @cisr_id IS NOT NULL
		BEGIN
			UPDATE	Planing.CoveringIssueSHKRm
			SET 	return_qty = @retyrn_qty,
					return_dt = @dt,
					return_employee_id = @return_employee_id,
					return_recive_employee_id = @employee_id,
					return_stor_unit_residues_qty = @return_stor_unit_residues_qty
			WHERE	cisr_id = @cisr_id
					AND	return_dt IS NULL
		END
		
		IF @mis_id IS NOT NULL
		BEGIN
			SET @upload_doc_type_id = 3
			
			UPDATE	Warehouse.MaterialInSketch
			SET 	return_qty = @retyrn_qty,
					return_dt = @dt,					
					return_stor_unit_residues_qty = @return_stor_unit_residues_qty
			WHERE	mis_id = @mis_id
					AND	return_dt IS NULL	
					
			DELETE	ubd
			FROM	Synchro.UploadBuh_DocDetail ubd   
			WHERE	ubd.doc_id = @mis_id
						AND	ubd.upload_doc_type_id = @upload_doc_type_id	
		
			;
			WITH cte AS
				(
					SELECT	rmt.rmt_id,
							rmt.rmt_pid,
							rmt.rmt_id root_rmt_id
					FROM	Material.RawMaterialType rmt
					WHERE	rmt.rmt_pid IS NULL 
					UNION ALL
					SELECT	rmt.rmt_id,
							rmt.rmt_pid,
							c.root_rmt_id root_rmt_id
					FROM	Material.RawMaterialType rmt   
							INNER JOIN	cte c
								ON	c.rmt_id = rmt.rmt_pid
				)
			INSERT INTO Synchro.UploadBuh_DocDetail
				(
					doc_id,
					upload_doc_type_id,
					rmt_id,
					nds,
					amount
				)
			SELECT	st.mis_id,
					@upload_doc_type_id,
					c.root_rmt_id,
					smi.nds,
					(st.stor_unit_residues_qty - ISNULL(st.return_stor_unit_residues_qty, 0)) * (sma.amount / sma.stor_unit_residues_qty)
			FROM	Warehouse.MaterialInSketch st   
					INNER JOIN	Warehouse.SHKRawMaterialInfo smi
						ON	smi.shkrm_id = st.shkrm_id   
					INNER JOIN	Warehouse.SHKRawMaterialAmount sma
						ON	sma.shkrm_id = st.shkrm_id   
					INNER JOIN	cte c
						ON	smi.rmt_id = c.rmt_id
			WHERE	st.mis_id = @mis_id
					AND c.root_rmt_id != 144
	
			DELETE	ubd
			FROM	Synchro.UploadBuh_Doc ubd   
			WHERE	ubd.doc_id = @mis_id
					AND	ubd.upload_doc_type_id = @upload_doc_type_id	
	
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
			SELECT	st.mis_id,
					@upload_doc_type_id,
					NULL,
					NULL,
					0,
					ts.office_id,
					st.return_dt
			FROM	Warehouse.MaterialInSketch st   
					INNER JOIN	Manufactory.TaskSample ts
						ON	ts.task_sample_id = st.task_sample_id
			WHERE	st.mis_id = @mis_id  	
		END
		
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 