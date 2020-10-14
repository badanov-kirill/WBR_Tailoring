CREATE PROCEDURE [Planing].[SketchPrePlanComment_Add]
	@spp_id INT,
	@employee_id INT,
	@comment VARCHAR(300)
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	
	SELECT	@error_text = CASE 
	      	                   WHEN spp.spp_id IS NULL THEN 'Кода предварительного плана ' + CAST(v.spp_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spp_id))v(spp_id)   
			LEFT JOIN	Planing.SketchPrePlan spp
				ON	spp.spp_id = v.spp_id 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END			
	
	BEGIN TRY
		INSERT INTO Planing.SketchPrePlanComment
			(
				spp_id,
				dt,
				employee_id,
				comment
			)
		VALUES
			(
				@spp_id,
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
	