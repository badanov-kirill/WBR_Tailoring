CREATE PROCEDURE [Products].[ProdArticleNomenclature_SetPhoto]
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @data_tab TABLE(pan_id INT PRIMARY KEY CLUSTERED NOT NULL)
	
	
	INSERT INTO @data_tab
		(
			pan_id
		)
	SELECT	v.pan_id
	FROM	(SELECT	ml.value('@pan[1]', 'int') pan_id
	    	 FROM	@data_xml.nodes('root/det')x(ml))v
	GROUP BY
		v.pan_id	
	
	SELECT	@error_text = 'Не найдены следующие коды :' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.pan_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Products.ProdArticleNomenclature pan
	      					ON	pan.pan_id = dt.pan_id
	      		WHERE	pan.pan_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	pan
		SET 	pics_dt         = @dt,
				employee_id     = @employee_id
		FROM	Products.ProdArticleNomenclature pan
				INNER JOIN	@data_tab dt
					ON	pan.pan_id = dt.pan_id
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