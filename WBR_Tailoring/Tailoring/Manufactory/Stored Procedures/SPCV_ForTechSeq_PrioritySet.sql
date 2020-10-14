CREATE PROCEDURE [Manufactory].[SPCV_ForTechSeq_PrioritySet]
	@spcvfts_id INT,
	@qp_id INT
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
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.QueuePriority qp
	   	WHERE	qp.qp_id = @qp_id
	   )
	BEGIN
	    RAISERROR('Приоритета очередности с кодом %d не существует', 16, 1, @qp_id)
	    RETURN
	END
	
	
	
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Manufactory.SPCV_ForTechSeq
		SET 	qp_id = @qp_id
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