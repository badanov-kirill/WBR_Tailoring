CREATE PROCEDURE [Synchro].[ProductsForEAN_GetForPub2]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @tab TABLE (pants_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		;
		MERGE Synchro.ProductsForEANCnt2 t
		USING (
		      	SELECT	pfe.pants_id
		      	FROM	Synchro.ProductsForEAN2 pfe   
		      			LEFT JOIN	Synchro.ProductsForEANCnt2 pfec
		      				ON	pfec.pants_id = pfe.pants_id
		      	WHERE	pfe.dt_publish IS NULL
		      			AND	ISNULL(pfec.cnt_publish, 0) < 10
		      ) s
				ON t.pants_id = s.pants_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	cnt_publish     = t.cnt_publish + 1,
		     		dt_create       = @dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pants_id,
		     		cnt_create,
		     		cnt_publish,
		     		dt,
		     		dt_create,
		     		dt_publish
		     	)
		     VALUES
		     	(
		     		s.pants_id,
		     		0,
		     		1,
		     		@dt,
		     		@dt,
		     		@dt
		     	) 
		     OUTPUT	INSERTED.pants_id
		     INTO	@tab (
		     		pants_id
		     	);	 
		
		SELECT	pfe.pants_id,
				e.ean
		FROM	@tab pfe   
				INNER JOIN	Manufactory.EANCode e
					ON	e.pants_id = pfe.pants_id
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