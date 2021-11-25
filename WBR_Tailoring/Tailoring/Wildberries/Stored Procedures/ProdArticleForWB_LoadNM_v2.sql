CREATE PROCEDURE [Wildberries].[ProdArticleForWB_LoadNM_v2]
	@pa_id INT,
	@imt_id INT,
	@imt_uid VARCHAR(36),
	@nm_tab Wildberries.LoadNomenclatureTab READONLY,
	@chrt_tab Wildberries.LoadNomenclatureTSTab READONLY
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		MERGE Wildberries.ProdArticleForWB t
		USING (
		      	SELECT	@pa_id      pa_id,
		      			dbo.uid2bin(@imt_uid) wb_uid,
		      			@imt_id     imt_id
		      ) s
				ON t.pa_id = s.pa_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	imt_uid     = s.wb_uid,
		     		imt_id      = s.imt_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pa_id,
		     		dt,
		     		send_dt,
		     		imt_uid,
		     		is_error,
		     		load_nm_dt,
		     		imt_id
		     	)
		     VALUES
		     	(
		     		s.pa_id,
		     		@dt,
		     		@dt,
		     		s.wb_uid,
		     		0,
		     		NULL,
		     		s.imt_id
		     	);
		
		WITH cte_target AS
		(
			SELECT	panfw.pan_id,
					panfw.pa_id,
					panfw.dt,
					panfw.nm_id,
					panfw.wb_uid
			FROM	Wildberries.ProdArticleNomenclatureForWB panfw
			WHERE	panfw.pa_id = @pa_id
		)
		MERGE cte_target AS t
		USING (
		      	SELECT	pan.pan_id,
		      			pan.pa_id,
		      			nt.sa_nm,
		      			nt.nm_id,
		      			dbo.uid2bin(nt.nm_uid) wb_uid
		      	FROM	Products.ProdArticleNomenclature pan   
		      			INNER JOIN	@nm_tab nt
		      				ON	pan.sa = nt.sa_nm
		      	WHERE	pan.pa_id = @pa_id
		      ) AS s
				ON t.pan_id = s.pan_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	nm_id      = s.nm_id,
		     		wb_uid     = s.wb_uid
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pan_id,
		     		pa_id,
		     		dt,
		     		nm_id,
		     		wb_uid
		     	)
		     VALUES
		     	(
		     		s.pan_id,
		     		s.pa_id,
		     		@dt,
		     		s.nm_id,
		     		s.wb_uid
		     	);
		
		WITH cte_target AS (
			SELECT	pants_id,
					wb_uid,
					chrt_id,
					dt
			FROM	Wildberries.ProdArticleNomenclatureTSForWB
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	Products.ProdArticleNomenclature pan   
			     				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
			     					ON	pants.pan_id = pan.pan_id
			     		WHERE	pants.pants_id = pants_id
			     				AND	pan.pa_id = @pa_id
			     	)
		)
		MERGE cte_target AS t
		USING (
		      	SELECT	pants.pants_id,
		      			dbo.uid2bin(ct.chrt_uid) wb_uid,
		      			ct.chrt_id
		      	FROM	Products.ProdArticleNomenclature pan   
		      			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
		      				ON	pan.pan_id = pants.pan_id   
		      			INNER JOIN	Products.TechSize ts
		      				ON	ts.ts_id = pants.ts_id   
		      			INNER JOIN	@chrt_tab ct
		      				ON	ct.nm_id = pan.nm_id
		      				AND	ct.ts_name = ts.ts_name
		      	WHERE	pan.pa_id = @pa_id
		      ) AS s
				ON t.pants_id = s.pants_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	wb_uid      = s.wb_uid,
		     		chrt_id     = s.chrt_id
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pants_id,
		     		wb_uid,
		     		chrt_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.pants_id,
		     		s.wb_uid,
		     		s.chrt_id,
		     		@dt
		     	);
		
		
		UPDATE	pa
		SET 	pa.imt_id = @imt_id
		FROM	Products.ProdArticle pa
		WHERE	pa.pa_id = @pa_id
				AND	pa.is_deleted = 0
				AND	pa.imt_id IS NULL
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Products.ProdArticle pa2
				   		WHERE	pa2.imt_id = @imt_id
				   	)
		
		UPDATE	pan
		SET 	nm_id = nt.nm_id
		FROM	Products.ProdArticleNomenclature pan
				INNER JOIN	@nm_tab nt
					ON	pan.sa = nt.sa_nm
		WHERE	pan.pa_id = @pa_id
				AND	pan.is_deleted = 0
				AND	pan.nm_id IS NULL
				AND	NOT EXISTS(
				   		SELECT	1
				   		FROM	Products.ProdArticleNomenclature pan2
				   		WHERE	pan2.nm_id = nt.nm_id
				   	)
		
		IF NOT EXISTS (
		   	SELECT	1
		   	FROM	Wildberries.ProdArticleNomenclatureForWB panfw
		   	WHERE	panfw.pa_id = @pa_id
		   			AND	panfw.nm_id IS NULL
		   )
		BEGIN
		    UPDATE	Wildberries.ProdArticleForWB
		    SET 	load_nm_dt = @dt,
		    		is_error = 0
		    WHERE	pa_id = @pa_id
		    
		    DELETE	
		    FROM	Wildberries.ProdArticleForWBCnt
		    WHERE	pa_id = @pa_id
		    
		    DELETE	
		    FROM	Wildberries.ProdArticleForWBError
		    WHERE	pa_id = @pa_id
		END
		
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
GO