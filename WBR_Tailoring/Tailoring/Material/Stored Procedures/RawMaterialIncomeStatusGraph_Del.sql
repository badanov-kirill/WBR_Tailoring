CREATE PROCEDURE [Material].[RawMaterialIncomeStatusGraph_Del]
	@rmis_src_id INT,
	@rmis_dst_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Material.RawMaterialIncomeStatusGraph rmisg
	   	WHERE	rmisg.rmis_src_id = @rmis_src_id
	   			AND	rmisg.rmis_dst_id = @rmis_dst_id
	   )
	BEGIN
	    RAISERROR('Такого перехода статусов не существует', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		DELETE	
		FROM	Material.RawMaterialIncomeStatusGraph
		    	OUTPUT	DELETED.rmis_src_id,
		    			DELETED.rmis_dst_id,
		    			@dt,
		    			@employee_id,
		    			1
		    	INTO	History.RawMaterialIncomeStatusGraph (
		    			rmis_src_id,
		    			rmis_dst_id,
		    			dt,
		    			employee_id,
		    			is_deleted
		    		)
		WHERE	rmis_src_id = @rmis_src_id
				AND	rmis_dst_id = @rmis_dst_id
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