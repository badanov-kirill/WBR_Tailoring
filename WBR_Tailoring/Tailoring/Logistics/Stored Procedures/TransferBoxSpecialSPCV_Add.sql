CREATE PROCEDURE [Logistics].[TransferBoxSpecialSPCV_Add]
	@transfer_box_id BIGINT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @office_id INT
	DECLARE @data_tab TABLE(spcv_id INT)
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN tbs.transfer_box_id IS NULL THEN 'Спец коробки с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' не существует.'
	      	                   WHEN tb.close_dt IS NOT NULL THEN 'Коробка с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' уже закрыта.'
	      	                   WHEN tbs.shipping_dt IS NOT NULL THEN 'Коробка с кодом ' + CAST(v.transfer_box_id AS VARCHAR(20)) + ' уже закрыта.'
	      	                   ELSE NULL
	      	              END,
			@office_id = tbs.office_id
	FROM	(VALUES(@transfer_box_id))v(transfer_box_id)   
			LEFT JOIN	Logistics.TransferBoxSpecial tbs   
			INNER JOIN	Logistics.TransferBox tb
				ON	tb.transfer_box_id = tbs.transfer_box_id
				ON	tbs.transfer_box_id = v.transfer_box_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @data_tab
		(
			spcv_id
		)
	SELECT	ml.value('@spcv[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	@data_tab dt
	   )
	BEGIN
	    RAISERROR('Не выбрано ни одного цветоварианта', 16, 1)
	    RETURN
	END
	
	SELECT	@error_text = 'Не найдены следующие коды цветовариантов:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spcv_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPlanColorVariant spcv
	      					ON	spcv.spcv_id = dt.spcv_id
	      		WHERE	spcv.spcv_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.sew_office_id != @office_id THEN 'Не все цветоварианты из одного офиса'
	      	                   WHEN tbss.spcv_id IS NOT NULL THEN 'Цветовариант с кодом ' + CAST(spcv.spcv_id AS VARCHAR(10)) + ' уже в коробке.'
	      	                   ELSE NULL
	      	              END
	FROM	@data_tab dt   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = dt.spcv_id   
			LEFT JOIN	Logistics.TransferBoxSpecialSPCV tbss
				ON	tbss.spcv_id = spcv.spcv_id
				AND	tbss.transfer_box_id = @transfer_box_id
	WHERE	spcv.sew_office_id != @office_id
			OR	tbss.spcv_id IS NOT NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		INSERT INTO Logistics.TransferBoxSpecialSPCV
			(
				transfer_box_id,
				spcv_id
			)
		SELECT	@transfer_box_id,
				dt.spcv_id
		FROM	@data_tab dt
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
