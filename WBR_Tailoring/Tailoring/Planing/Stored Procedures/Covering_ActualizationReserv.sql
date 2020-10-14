CREATE PROCEDURE [Planing].[Covering_ActualizationReserv]
	@covering_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.Covering c
	   	WHERE	c.covering_id = @covering_id
	   )
	BEGIN
	    RAISERROR('Выдача с кодом %d не существует', 16, 1, @covering_id)
	END
	
	DECLARE @covering_reserv TABLE (covering_id INT, spcv_id INT, spcvc_id INT, shkrm_id INT, okei_id INT, quantity DECIMAL(9, 3), pre_cost DECIMAL(9, 2))
	DECLARE @spcv_tab TABLE (covering_id INT, spcv_id INT, is_added BIT)
	
	INSERT INTO @spcv_tab
		(
			covering_id,
			spcv_id,
			is_added
		)
	SELECT	cd.covering_id,
			cd.spcv_id,
			0
	FROM	Planing.CoveringDetail cd
	WHERE	cd.covering_id = @covering_id
	
	INSERT INTO @covering_reserv
		(
			covering_id,
			spcv_id,
			spcvc_id,
			shkrm_id,
			okei_id,
			quantity,
			pre_cost
		)
	SELECT	st.covering_id,
			st.spcv_id,
			spcvc.spcvc_id,
			smr.shkrm_id,
			smr.okei_id,
			smr.quantity,
			COALESCE(sma0.amount / sma0.stor_unit_residues_qty, oa1.price, oa2.price, oa3.price, 0) * smr.quantity pre_cost
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = st.spcv_id   
			INNER JOIN	Warehouse.SHKRawMaterialReserv smr
				ON	smr.spcvc_id = spcvc.spcvc_id   
			INNER JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = smr.shkrm_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			LEFT JOIN	Warehouse.SHKRawMaterialAmount sma0
				ON	sma0.shkrm_id = smr.shkrm_id
				AND	sma0.final_dt IS NOT NULL
				AND	sma0.amount != 0   
			OUTER APPLY (
			      	SELECT	AVG(v.price) price
			      	FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
			      	    	 FROM	Warehouse.SHKRawMaterialAmount sma   
			      	    	 		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
			      	    	 			ON	smi.shkrm_id = sma.shkrm_id
			      	    	 WHERE	smi.rmt_id = smai.rmt_id
			      	    	 		AND	smi.art_id = smai.art_id
			      	    	 		AND	sma.final_dt IS NOT NULL
			      	    	 		AND	sma.amount != 0
			      	    	 ORDER BY
			      	    	 	sma.final_dt DESC)v
			      ) oa1
	OUTER APPLY (
	      	SELECT	AVG(v.price) price
	      	FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    	 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 			ON	smi.shkrm_id = sma.shkrm_id
	      	    	 WHERE	smi.rmt_id = smai.rmt_id
	      	    	 		AND	sma.final_dt IS NOT NULL
	      	    	 		AND	sma.amount != 0
	      	    	 ORDER BY
	      	    	 	sma.final_dt DESC)v
	      ) oa2
	OUTER APPLY (
	      	SELECT	AVG(v.price) price
	      	FROM	(SELECT	TOP(10) sma.amount / sma.stor_unit_residues_qty price
	      	    	 FROM	Warehouse.SHKRawMaterialAmount sma   
	      	    	 		INNER JOIN	Warehouse.SHKRawMaterialInfo smi
	      	    	 			ON	smi.shkrm_id = sma.shkrm_id   
	      	    	 		INNER JOIN	Material.RawMaterialType rmt2
	      	    	 			ON	rmt2.rmt_id = smi.rmt_id
	      	    	 WHERE	rmt.rmt_pid = rmt2.rmt_pid
	      	    	 		AND	sma.final_dt IS NOT NULL
	      	    	 		AND	sma.amount != 0
	      	    	 ORDER BY
	      	    	 	sma.final_dt DESC)v
	      ) oa3
	      
	IF NOT EXISTS (SELECT 1 FROM @covering_reserv cr)
	BEGIN
		RAISERROR('Нет текущих резервов, которыми можно актуализировать резервы выдачи',16,1)
		RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		DELETE	
		FROM	Planing.CoveringReserv
		WHERE	covering_id = @covering_id
		
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
		SELECT	cr.covering_id,
				cr.spcvc_id,
				cr.shkrm_id,
				cr.okei_id,
				cr.quantity,
				@dt,
				@employee_id,
				cr.pre_cost
		FROM	@covering_reserv cr		
		
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
	