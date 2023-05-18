
CREATE PROCEDURE [Warehouse].[SHKRawMaterialActualInfo_Upd]
	@shkrm_id INT,
	@rmt_id INT,
	@art_name VARCHAR(12),
	@color_id INT,
	@suppliercontract_id INT,
	@su_id INT,
	@okei_id INT,
	@qty DECIMAL(9, 2),
	@stor_unit_residues_okei_id INT,
	@stor_unit_residues_qty DECIMAL(9, 2),
	@amount DECIMAL(19, 8),
	@nds TINYINT,
	@employee_id INT,
	@frame_width SMALLINT = NULL,
	@is_defected BIT = 0,
	@defected_descr VARCHAR(900) = NULL,
	@is_deleted BIT = 0,
	@gross_mass INT = NULL,
	@tissue_density SMALLINT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @art_id INT
	DECLARE @proc_id INT
	DECLARE @rmtv_out TABLE (rmtv_id INT)
		
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(v.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != @stor_unit_residues_okei_id THEN 
	      	                        'Для типа материала не совпадает использованная еденица хранения остатков, перечитайте данные, и заполните остаток по новому'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@rmt_id))v(rmt_id)   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	v.rmt_id = rmt.rmt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан.'
	      	                   WHEN sms.state_id NOT IN (1, 2, 3, 11, 12) THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' в статусе ' + smsd.state_name +
	      	                        'редактировать уже нельзя.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm   
			INNER JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = sm.shkrm_id   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsd
				ON	smsd.state_id = sms.state_id
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = v.shkrm_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Material.ClothColor cc
	   )
	BEGIN
	    RAISERROR('Цвета с кодом %d не существует', 16, 1, @color_id)
	    RETURN
	END
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Suppliers.SupplierContract sc
	   	WHERE	sc.suppliercontract_id = @suppliercontract_id
	   )
	BEGIN
	    RAISERROR('Договора поставщика с кодом %d не существует', 16, 1, @suppliercontract_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	RefBook.SpaceUnit su
	   	WHERE	su.su_id = @su_id
	   )
	BEGIN
	    RAISERROR('Грузового места с кодом %d не существует', 16, 1, @su_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Qualifiers.OKEI o
	   	WHERE	o.okei_id = @okei_id
	   )
	BEGIN
	    RAISERROR('Еденицы измерения с кодом %d не существует', 16, 1, @okei_id)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN n.nds IS NULL THEN 'НДС ' + CAST(v.nds AS VARCHAR(5)) + ' отсутствует в справочнике'
	      	                   WHEN n.is_deleted = 1 THEN 'НДС ' + CAST(v.nds AS VARCHAR(5)) + ' запрещено использовать'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@nds))v(nds)   
			LEFT JOIN	RefBook.NDS n
				ON	n.nds = v.nds
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	IF @is_defected = 1
	   AND @defected_descr IS NULL
	BEGIN
	    RAISERROR('Не указано описание брака', 16, 1)
	    RETURN
	END
	
	INSERT INTO Material.Article
		(
			art_name
		)
	SELECT	@art_name
	WHERE	NOT EXISTS (
	     		SELECT	1
	     		FROM	Material.Article a
	     		WHERE	a.art_name = @art_name
	     	)
	
	IF @@ROWCOUNT > 0
	BEGIN
	    SET @art_id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
	    SELECT	@art_id = a.art_id
	    FROM	Material.Article a
	    WHERE	a.art_name = @art_name
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Warehouse.SHKRawMaterialActualInfo
		SET 	suppliercontract_id = @suppliercontract_id,
				rmt_id = @rmt_id,
				art_id = @art_id,
				color_id = @color_id,
				su_id = @su_id,
				okei_id = @okei_id,
				qty = @qty,
				stor_unit_residues_okei_id = @stor_unit_residues_okei_id,
				stor_unit_residues_qty = @stor_unit_residues_qty,
				dt = @dt,
				employee_id = @employee_id,
				frame_width = @frame_width,
				is_defected = @is_defected,
				is_deleted = @is_deleted,
				nds = @nds,
				gross_mass = @gross_mass,
				tissue_density = @tissue_density
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
						INSERTED.tissue_density,
						INSERTED.fabricator_id
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
						tissue_density,
						fabricator_id
					)
		WHERE	shkrm_id = @shkrm_id
		
		UPDATE	Warehouse.SHKRawMaterialInfo
		SET 	suppliercontract_id = @suppliercontract_id,
				rmt_id = @rmt_id,
				art_id = @art_id,
				color_id = @color_id,
				su_id = @su_id,
				frame_width = @frame_width,
				nds = @nds,
				tissue_density = @tissue_density				
				OUTPUT	INSERTED.shkrm_id,
						INSERTED.doc_id,
						INSERTED.doc_type_id,
						INSERTED.suppliercontract_id,
						INSERTED.rmt_id,
						INSERTED.art_id,
						INSERTED.color_id,
						INSERTED.su_id,
						@dt,
						@employee_id,
						INSERTED.frame_width,
						@proc_id,
						INSERTED.nds,
						INSERTED.tissue_density
				INTO	History.SHKRawMaterialInfo (
						shkrm_id,
						doc_id,
						doc_type_id,
						suppliercontract_id,
						rmt_id,
						art_id,
						color_id,
						su_id,
						dt,
						employee_id,
						frame_width,
						proc_id,
						nds,
						tissue_density
					)
		WHERE	shkrm_id = @shkrm_id
		
		--UPDATE	Warehouse.SHKRawMaterialAmount
		--SET 	stor_unit_residues_okei_id = @stor_unit_residues_okei_id,
		--		stor_unit_residues_qty     = @stor_unit_residues_qty,
		--		amount                     = @amount,
		--		gross_mass                 = @gross_mass
		--		OUTPUT	INSERTED.shkrm_id,
		--				INSERTED.stor_unit_residues_okei_id,
		--				INSERTED.stor_unit_residues_qty,
		--				INSERTED.amount,
		--				INSERTED.gross_mass,
		--				@proc_id,
		--				@dt,
		--				@employee_id
		--		INTO	History.SHKRawMaterialAmount (
		--				shkrm_id,
		--				stor_unit_residues_okei_id,
		--				stor_unit_residues_qty,
		--				amount,
		--				gross_mass,
		--				proc_id,
		--				dt,
		--				employee_id
		--			)
		--WHERE	shkrm_id = @shkrm_id
		
		INSERT INTO Material.RawMaterialTypeVariant
			(
				rmt_id,
				art_id,
				frame_width,
				rmt_astra_id
			)OUTPUT	INSERTED.rmtv_id
			 INTO	@rmtv_out (
			 		rmtv_id
			 	)
		SELECT	@rmt_id,
				@art_id,
				@frame_width,
				NULL
		WHERE	NOT EXISTS (
		     		SELECT	1
		     		FROM	Material.RawMaterialTypeVariant rmtv
		     		WHERE	rmtv.rmt_id = @rmt_id
		     				AND	rmtv.art_id = @art_id
		     				AND	(rmtv.frame_width = @frame_width OR (rmtv.frame_width IS NULL AND @frame_width IS NULL))
		     	)
		
		INSERT INTO SyncFinance.RawMaterialTypeVariantUpload
			(
				rmtv_id,
				dt,
				employee_id
			)
		SELECT	rmtv_id,
				@dt,
				@employee_id
		FROM	@rmtv_out
		
		IF @is_defected = 1
		BEGIN
		    ;
		    MERGE Warehouse.SHKRawMaterialDefectDescr t
		    USING (
		          	SELECT	@shkrm_id        shkrm_id,
		          			@defected_descr defected_descr,
		          			@stor_unit_residues_okei_id stor_unit_residues_okei_id,
		          			@stor_unit_residues_qty stor_unit_residues_qty,
		          			@dt              dt,
		          			@employee_id     employee_id
		          ) s
		    		ON s.shkrm_id = t.shkrm_id
		    WHEN MATCHED THEN 
		         UPDATE	
		         SET 	descr           = s.defected_descr,
		         		okei_id         = s.stor_unit_residues_okei_id,
		         		qty             = s.stor_unit_residues_qty,
		         		dt              = s.dt,
		         		employee_id     = s.employee_id
		    WHEN NOT MATCHED THEN 
		         INSERT
		         	(
		         		shkrm_id,
		         		descr,
		         		okei_id,
		         		qty,
		         		dt,
		         		employee_id
		         	)
		         VALUES
		         	(
		         		s.shkrm_id,
		         		s.defected_descr,
		         		s.stor_unit_residues_okei_id,
		         		s.stor_unit_residues_qty,
		         		s.dt,
		         		s.employee_id
		         	)
		         OUTPUT	INSERTED.shkrm_id,
		         		INSERTED.descr,
		         		INSERTED.dt,
		         		INSERTED.employee_id,
		         		@proc_id
		         INTO	History.SHKRawMaterialDefectDescr (
		         		shkrm_id,
		         		descr,
		         		dt,
		         		employee_id,
		         		proc_id
		         	);
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		--WITH LOG;
	END CATCH 