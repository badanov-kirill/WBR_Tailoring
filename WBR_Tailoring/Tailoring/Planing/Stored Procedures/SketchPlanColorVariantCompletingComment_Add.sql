CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompletingComment_Add]
	@spcvc_id INT,
	@employee_id INT,
	@comment VARCHAR(300)
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcvc.spcvc_id IS NULL THEN 'Кода потребноcти материала цветоварианта ' + CAST(v.spcvc_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcvc_id))v(spcvc_id)   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = v.spcvc_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		INSERT INTO Planing.SketchPlanColorVariantCompletingComment
			(
				spcvc_id,
				dt,
				employee_id,
				comment
			)
		VALUES
			(
				@spcvc_id,
				@dt,
				@employee_id,
				@comment
			)
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
	