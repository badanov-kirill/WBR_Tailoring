CREATE PROCEDURE [Synchro].[Upload_DetMirShip_BuhVas_Loaded]
	@sfp_id INT,
	@rv_bigint BIGINT
AS
	SET NOCOUNT ON
	
	DECLARE @rv ROWVERSION = CAST(@rv_bigint AS ROWVERSION)
	
	BEGIN TRY
		DELETE	
		FROM	Synchro.Upload_DetMirShip_BuhVas
		WHERE	sfp_id = @sfp_id
				AND	rv = @rv
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
GO
