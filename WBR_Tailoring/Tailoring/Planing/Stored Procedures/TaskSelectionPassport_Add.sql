CREATE PROCEDURE [Planing].[TaskSelectionPassport_Add]
	@spcv_id INT,
	@employee_id INT,
	@is_print BIT = 0,
	@only_cloth BIT = 1
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @print_dt DATETIME2(0)
	DECLARE @print_employee_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @cv_status_ready TINYINT = 2 --Цветовариант готов к отшиву
	DECLARE @cv_status_sel_pasp TINYINT = 3 --Сбор паспортов на материал
	DECLARE @shkrm_tab TABLE(shkrm_id INT PRIMARY KEY CLUSTERED, suppliercontract_id INT, rmt_id INT, art_id INT, color_id INT, frame_width SMALLINT, quantity DECIMAL(9,3), okei_id INT)
	DECLARE @tsp_output TABLE(tsp_id INT, spcv_id INT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(v.spcv_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN spcv.cvs_id NOT IN (@cv_status_ready, @cv_status_sel_pasp) THEN 'Статус цветоварианта ' + cvs.cvs_name +
	      	                        ', сбор паспортов запрещен.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcv_id))v(spcv_id)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.ColorVariantStatus cvs
				ON	cvs.cvs_id = spcv.cvs_id
				ON	spcv.spcv_id = v.spcv_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @shkrm_tab
	  (
	    shkrm_id,
	    suppliercontract_id,
	    rmt_id,
	    art_id,
	    color_id,
	    frame_width,
	    quantity,
	    okei_id
	  )
	SELECT	smr.shkrm_id,
			smai.suppliercontract_id,
			smai.rmt_id,
			smai.art_id,
			smai.color_id,
			smai.frame_width,
			SUM(smr.quantity) quantity, 
			smr.okei_id
	FROM	Planing.SketchPlanColorVariant spcv   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = spcv.spcv_id   
			LEFT JOIN	Material.CompletingIsCloth cic
				ON	cic.completing_id = spcvc.completing_id   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id
	WHERE	spcv.spcv_id = @spcv_id
			AND ((@only_cloth = 1 AND cic.completing_id IS NOT NULL) OR @only_cloth = 0)
	GROUP BY smr.shkrm_id,
			smai.suppliercontract_id,
			smai.rmt_id,
			smai.art_id,
			smai.color_id,
			smai.frame_width,
			smr.okei_id
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@shkrm_tab
	   )
	BEGIN
	    RAISERROR('Нет резервов для подбора паспартов', 16, 1)
	    RETURN
	END
	
	IF @is_print = 1
	BEGIN
	    SET @print_dt = @dt
	    SET @print_employee_id = @employee_id
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Planing.TaskSelectionPassport
		  (
		    create_dt,
		    create_employee_id,
		    print_dt,
		    print_employee_id,
		    close_dt,
		    close_employee_id,
		    spcv_id
		  )OUTPUT	INSERTED.tsp_id,
		   		INSERTED.spcv_id
		   INTO	@tsp_output (
		   		tsp_id,
		   		spcv_id
		   	)
		VALUES
		  (
		    @dt,
		    @employee_id,
		    @print_dt,
		    @print_employee_id,
		    NULL,
		    NULL,
		    @spcv_id
		  )
		
		INSERT INTO Planing.TaskSelectionPassportDetail
		  (
		    tsp_id,
		    shkrm_id,
		    suppliercontract_id,
		    rmt_id,
		    art_id,
		    color_id,
		    frame_width,
		    employee_id,
		    dt,
		    quantity,
		    okei_id
		  )
		SELECT	tspo.tsp_id,
				srmt.shkrm_id,
				srmt.suppliercontract_id,
				srmt.rmt_id,
				srmt.art_id,
				srmt.color_id,
				srmt.frame_width,
				@employee_id,
				@dt,
				srmt.quantity, 
				srmt.okei_id
		FROM	@shkrm_tab srmt   
				CROSS JOIN	@tsp_output tspo
		
		COMMIT TRANSACTION
		
		SELECT	tspo.tsp_id,
				CAST(@dt AS DATETIME)     dt,
				srmt.shkrm_id,
				a.art_name,
				rmt.rmt_name,
				s.supplier_name,
				cc.color_name,
				srmt.quantity,
				o.symbol okei_symbol,
				smai.stor_unit_residues_qty
		FROM	@shkrm_tab srmt   
				CROSS JOIN	@tsp_output tspo   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = srmt.rmt_id   
				INNER JOIN	Material.Article a
					ON	a.art_id = srmt.art_id   
				INNER JOIN	Suppliers.SupplierContract sc
					ON	sc.suppliercontract_id = srmt.suppliercontract_id   
				INNER JOIN	Suppliers.Supplier s
					ON	s.supplier_id = sc.supplier_id     
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = srmt.color_id
				INNER JOIN Qualifiers.OKEI o
					ON o.okei_id = srmt.okei_id
				LEFT JOIN Warehouse.SHKRawMaterialActualInfo smai
					ON srmt.shkrm_id = smai.shkrm_id
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