CREATE PROCEDURE [Manufactory].[SPCV_ForTechSeq_ProirityLevelSet]
	@spcvfts_id INT,
	@proirity_level TINYINT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @tss_id INT
	
	SELECT	@error_text = CASE 
	      	                   WHEN sfts.spcvfts_id IS NULL THEN 'Задания с кодом ' + CAST(v.spcvfts_id AS VARCHAR(10)) + ' не существует.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@spcvfts_id))v(spcvfts_id)   
			LEFT JOIN	Manufactory.SPCV_ForTechSeq sfts
				ON	sfts.spcvfts_id = v.spcvfts_id  
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Manufactory.SPCV_ForTechSeq
		SET 	proirity_level = @proirity_level
		WHERE	spcvfts_id = @spcvfts_id
		
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