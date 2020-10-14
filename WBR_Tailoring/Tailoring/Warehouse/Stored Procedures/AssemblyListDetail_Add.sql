CREATE PROCEDURE [Warehouse].[AssemblyListDetail_Add]
	@al_id INT,
	@employee_id INT,
	@shkrm_id INT,
	@comment VARCHAR(200) = NULL
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN sm.shkrm_id IS NULL THEN 'Штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN smai.shkrm_id IS NULL THEN 'Штрихкод ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' не описан.'
	      	                   WHEN sms.shkrm_id IS NULL THEN 'У штрихкода ' + CAST(v.shkrm_id AS VARCHAR(10)) +
	      	                        ' нет статуса, операции со штрихкодом запрещены. Обратитесь к руководителю'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@shkrm_id))v(shkrm_id)   
			LEFT JOIN	Warehouse.SHKRawMaterial sm
				ON	sm.shkrm_id = v.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialState sms
				ON	sms.shkrm_id = sm.shkrm_id   
			LEFT JOIN	Warehouse.SHKRawMaterialActualInfo smai
				ON	smai.shkrm_id = sm.shkrm_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN al.al_id IS NULL THEN 'Заказа в производство с номером ' + CAST(v.al_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN al.close_dt IS NOT NULL THEN 'Документ закрыт, изменять нельзя'
	      	                   WHEN oa.is_shk IS NOT NULL THEN 'ШК ' + CAST(@shkrm_id AS VARCHAR(10)) + ' уже в документе.'
	      	                   WHEN oa2.al_id IS NOT NULL THEN 'ШК ' + CAST(@shkrm_id AS VARCHAR(10)) + ' присутствует в незакрытом сборочном листе ' + CAST(oa2.al_id AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@al_id))v(al_id)   
			LEFT JOIN	Warehouse.AssemblyList al
				ON	al.al_id = v.al_id   
			OUTER APPLY (
			      	SELECT	TOP(1) 1 is_shk
			      	FROM	Warehouse.AssemblyListDetail asd
			      	WHERE	asd.al_id = al.al_id
			      			AND	asd.shkrm_id = @shkrm_id
			      ) oa
	OUTER APPLY (
	      	SELECT	TOP(1) al2.al_id
	      	FROM	Warehouse.AssemblyList al2   
	      			INNER JOIN	Warehouse.AssemblyListDetail asd2
	      				ON	asd2.al_id = al2.al_id
	      	WHERE	al2.al_id != al.al_id
	      			AND	asd2.shkrm_id = @shkrm_id
	      			AND	al2.close_dt IS NOT NULL
	      ) oa2
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Warehouse.AssemblyListDetail
		  (
		    al_id,
		    shkrm_id,
		    employee_id,
		    dt,
		    comment
		  )
		VALUES
		  (
		    @al_id,
		    @shkrm_id,
		    @employee_id,
		    @dt,
		    @comment
		  )
		
		SELECT	smai.shkrm_id,
				rmt.rmt_name,
				a.art_name,
				cc.color_name,
				sp.place_name,
				zor.zor_name,
				@comment comment
		FROM	Warehouse.SHKRawMaterialActualInfo smai   
				INNER JOIN	Material.RawMaterialType rmt
					ON	rmt.rmt_id = smai.rmt_id   
				INNER JOIN	Material.Article a
					ON	a.art_id = smai.art_id   
				INNER JOIN	Material.ClothColor cc
					ON	cc.color_id = smai.color_id   
				LEFT JOIN	Warehouse.SHKRawMaterialOnPlace smop   
				INNER JOIN	Warehouse.StoragePlace sp
					ON	sp.place_id = smop.place_id   
				INNER JOIN	Warehouse.ZoneOfResponse zor
					ON	zor.zor_id = sp.zor_id
					ON	smop.shkrm_id = smai.shkrm_id
		WHERE	smai.shkrm_id = @shkrm_id
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
	