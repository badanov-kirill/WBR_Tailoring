CREATE PROCEDURE [Material].[RawMaterialTypeLimitCancellation_Set]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @data_tab TABLE (rmt_id INT, stor_unit_residues_qty DECIMAL(9, 3))
	DECLARE @error_text VARCHAR(MAX)
	
	INSERT INTO @data_tab
		(
			rmt_id,
			stor_unit_residues_qty
		)
	SELECT	ml.value('@rmt[1]', 'int'),
			ml.value('@qty[1]', 'decimal(9,3)')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(dt.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = dt.rmt_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		MERGE Material.RawMaterialTypeLimitCancellation t
		USING (
		      	SELECT	dt.rmt_id,
		      			dt.stor_unit_residues_qty
		      	FROM	@data_tab dt
		      	WHERE	dt.stor_unit_residues_qty > 0
		      ) s
				ON t.rmt_id = s.rmt_id
		WHEN MATCHED AND t.stor_unit_residues_qty != s.stor_unit_residues_qty THEN 
		     UPDATE	
		     SET 	t.stor_unit_residues_qty = s.stor_unit_residues_qty,
		     		t.dt = @dt,
		     		t.employee_id = @employee_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		rmt_id,
		     		stor_unit_residues_qty,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.rmt_id,
		     		s.stor_unit_residues_qty,
		     		@dt,
		     		@employee_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
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