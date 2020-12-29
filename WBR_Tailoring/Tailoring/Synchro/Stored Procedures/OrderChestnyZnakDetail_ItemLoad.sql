CREATE PROCEDURE [Synchro].[OrderChestnyZnakDetail_ItemLoad]
	@oczd_id INT,
	@block_uid CHAR(36),
	@numbers Synchro.OrderChestnyZnakItemTab READONLY
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @block_uid_bin BINARY(16) = dbo.uid2bin(@block_uid)
	DECLARE @block_uid_id INT
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Manufactory.OrderChestnyZnakBlock
			(
				block_uid
			)
		SELECT	@block_uid_bin
		WHERE	NOT EXISTS(
		     		SELECT	1
		     		FROM	Manufactory.OrderChestnyZnakBlock oczb
		     		WHERE	oczb.block_uid = @block_uid_bin
		     	)
		
		SELECT	@block_uid_id = oczb.block_id
		FROM	Manufactory.OrderChestnyZnakBlock oczb
		WHERE	oczb.block_uid = @block_uid_bin
		
		INSERT INTO Manufactory.OrderChestnyZnakDetailItem
			(
				oczd_id,
				code,
				gtin01,
				serial21,
				intrnal91,
				intrnal92,
				block_id
			)
		SELECT	@oczd_id,
				n.code,
				n.gtin01,
				n.serial21,
				n.intrnal91,
				n.intrnal92,
				@block_uid_id
		FROM	@numbers n
		WHERE NOT EXISTS(
		                	SELECT	1
		                	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi
		                	WHERE	oczdi.oczd_id = @oczd_id
		                			AND	oczdi.serial21 = n.serial21
		                )
		
		UPDATE	oczd
		SET 	load_item_dt = @dt
		FROM	Manufactory.OrderChestnyZnakDetail oczd
				OUTER APPLY (
				      	SELECT	COUNT(1) cnt
				      	FROM	Manufactory.OrderChestnyZnakDetailItem oczdi
				      	WHERE	oczdi.oczd_id = oczd.oczd_id
				      ) oa
		WHERE	oczd.oczd_id = @oczd_id
				AND oczd.cnt = ISNULL(oa.cnt, 0)
		
		IF @@ROWCOUNT != 0
		BEGIN
		    DELETE	
		    FROM	Synchro.OrderChestnyZnakCntLoadItem
		    WHERE	oczd_id = @oczd_id
		END
		
		UPDATE	ocz
		SET 	close_dt = @dt
		FROM	Manufactory.OrderChestnyZnak ocz
				INNER JOIN	Manufactory.OrderChestnyZnakDetail oczd
					ON	oczd.ocz_id = ocz.ocz_id
		WHERE	oczd.oczd_id = @oczd_id
				AND	NOT EXISTS (
				   		SELECT	1
				   		FROM	Manufactory.OrderChestnyZnakDetail oczd2
				   		WHERE	oczd2.ocz_id = oczd.ocz_id
				   				AND	oczd2.load_item_dt IS NULL
				   	)
		
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH
	
	
	