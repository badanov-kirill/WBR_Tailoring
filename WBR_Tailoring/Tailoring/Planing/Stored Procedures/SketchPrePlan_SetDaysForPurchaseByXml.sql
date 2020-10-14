CREATE PROCEDURE [Planing].[SketchPrePlan_SetDaysForPurchaseByXml]
	@data_xml XML,
	@days_for_purchase SMALLINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	
	
	DECLARE @data_tab TABLE(spp_id INT PRIMARY KEY CLUSTERED)
	
	
	INSERT INTO @data_tab
		(
			spp_id
		)
	SELECT	ml.value('@spp[1]', 'int')
	FROM	@data_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = 'Не найдены следующие коды строчек предвартительного плана:' + CHAR(10)
	      	+ (
	      		SELECT	DISTINCT CAST(ISNULL(dt.spp_id, 0) AS VARCHAR(10)) + CHAR(10)
	      		FROM	@data_tab dt   
	      				LEFT JOIN	Planing.SketchPrePlan spp
	      					ON	spp.spp_id = dt.spp_id
	      		WHERE	spp.spp_id IS NULL
	      		FOR XML	PATH('')
	      	)	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	s
		SET 	days_for_purchase = @days_for_purchase
		FROM	Planing.SketchPrePlan spp
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = spp.sketch_id
				INNER JOIN	@data_tab dt
					ON	dt.spp_id = spp.spp_id
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