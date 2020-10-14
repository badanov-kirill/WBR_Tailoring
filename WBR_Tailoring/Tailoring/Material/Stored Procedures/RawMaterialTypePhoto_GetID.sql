CREATE PROCEDURE [Material].[RawMaterialTypePhoto_GetID]
	@shkrm_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @rmt_id INT
	DECLARE @art_id INT
	DECLARE @color_id INT
	DECLARE @frame_width SMALLINT
	DECLARE @supplier_id INT
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @rmt_name VARCHAR(100)
	DECLARE @art_name VARCHAR(12)
	DECLARE @color_name VARCHAR(50)
	DECLARE @supplier_name VARCHAR(50)
	
	SELECT	@error_text = CASE 
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не описан, возможно он уже удален.'
	      	                   ELSE NULL
	      	              END,
			@rmt_id            = smai.rmt_id,
			@art_id            = smai.art_id,
			@color_id          = smai.color_id,
			@frame_width       = smai.frame_width,
			@supplier_id       = sc.supplier_id,
			@rmt_name          = rmt.rmt_name,
			@art_name          = a.art_name,
			@color_name        = cc.color_name,
			@supplier_name     = s.supplier_name
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterialInfo smai   
			INNER JOIN	Suppliers.SupplierContract sc   
			INNER JOIN	Suppliers.Supplier s
				ON	s.supplier_id = sc.supplier_id
				ON	sc.suppliercontract_id = smai.suppliercontract_id   
			INNER JOIN	Material.RawMaterialType rmt
				ON	rmt.rmt_id = smai.rmt_id   
			INNER JOIN	Material.Article a
				ON	a.art_id = smai.art_id   
			INNER JOIN	Material.ClothColor cc
				ON	cc.color_id = smai.color_id
				ON	smai.shkrm_id = v.shkrm_id  
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		MERGE Material.RawMaterialTypePhoto t
		USING (
		      	SELECT	@rmt_id          rmt_id,
		      			@art_id          art_id,
		      			@color_id        color_id,
		      			@frame_width     frame_width,
		      			@supplier_id     supplier_id
		      ) s
				ON s.rmt_id = t.rmt_id
				AND s.art_id = t.art_id
				AND s.color_id = t.color_id
				AND ISNULL(s.frame_width, 0) = ISNULL(t.frame_width, 0)
				AND s.supplier_id = t.supplier_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	dt              = @dt,
		     		employee_id     = @employee_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		rmt_id,
		     		art_id,
		     		color_id,
		     		frame_width,
		     		supplier_id,
		     		dt,
		     		employee_id
		     	)
		     VALUES
		     	(
		     		s.rmt_id,
		     		s.art_id,
		     		s.color_id,
		     		s.frame_width,
		     		s.supplier_id,
		     		@dt,
		     		@employee_id
		     	) 
		     OUTPUT	INSERTED.rmtp_id,
		     		@rmt_name rmt_name,
		     		@art_name art_name,
		     		@color_name color_name,
		     		@supplier_name supplier_name;
		
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