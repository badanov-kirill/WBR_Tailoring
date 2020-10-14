CREATE PROCEDURE [Material].[CompletingRawMaterial_Set]
	@completing_id INT,
	@xml_data XML
AS
	SET NOCOUNT ON
	DECLARE @data_tab TABLE (rmt_id INT)
	DECLARE @error_text VARCHAR(MAX)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.Completing c
	   	WHERE	c.completing_id = @completing_id
	   )
	BEGIN
	    RAISERROR('Комплектации с кодом %d не существует', 16, 1, @completing_id)
	    RETURN
	END
	
	INSERT INTO @data_tab
	  (
	    rmt_id
	  )
	SELECT	ml.value('@rmt', 'int')
	FROM	@xml_data.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN rmt.rmt_id IS NULL THEN 'Типа материала с кодом ' + CAST(dt.rmt_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN rmt.stor_unit_residues_okei_id != c.okei_id THEN 'У материала ' + rmt.rmt_name + ' еденица хранения остатков(' + o.symbol + 
	      	                        ') не совпадает еденицей измерения комплектующей ' + c.completing_name + ' (' + o2.symbol + ')'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			LEFT JOIN	Material.RawMaterialType rmt   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = rmt.stor_unit_residues_okei_id
				ON	rmt.rmt_id = dt.rmt_id   
			LEFT JOIN	Material.Completing c   
			INNER JOIN	Qualifiers.OKEI o2
				ON	o2.okei_id = c.okei_id
				ON	c.completing_id = @completing_id
	WHERE	rmt.rmt_id IS NULL OR rmt.stor_unit_residues_okei_id != c.okei_id
	
	BEGIN TRY
		;
		MERGE Material.CompletingRawMaterial t
		USING @data_tab s
				ON t.completing_id = @completing_id
				AND s.rmt_id = t.rmt_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		completing_id,
		     		rmt_id
		     	)
		     VALUES
		     	(
		     		@completing_id,
		     		s.rmt_id
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.completing_id = @completing_id THEN 
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 