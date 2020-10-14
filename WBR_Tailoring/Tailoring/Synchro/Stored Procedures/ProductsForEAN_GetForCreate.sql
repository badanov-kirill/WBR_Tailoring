CREATE PROCEDURE [Synchro].[ProductsForEAN_GetForCreate]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @tab TABLE (pants_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	BEGIN TRY
		;
		MERGE Synchro.ProductsForEANCnt t
		USING (
		      	SELECT	pfe.pants_id
		      	FROM	Synchro.ProductsForEAN pfe   
		      			LEFT JOIN	Synchro.ProductsForEANCnt pfec
		      				ON	pfec.pants_id = pfe.pants_id
		      	WHERE	pfe.dt_create IS NULL
		      			AND	ISNULL(pfec.cnt_create, 0) < 10
		      ) s
				ON t.pants_id = s.pants_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	cnt_create     = t.cnt_create + 1,
		     		dt_create      = @dt
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
		     		1,
		     		0,
		     		@dt,
		     		@dt,
		     		@dt
		     	) 
		     OUTPUT	INSERTED.pants_id
		     INTO	@tab (
		     		pants_id
		     	);	
		
		SELECT	pfe.pants_id,
				b.brand_name,
				ISNULL(sj.subject_name_sf, sj.subject_name) subject_name,
				pa.sa + pan.sa sa,
				ts.ts_name,
				ISNULL(t.tnved_cod, '6206909000') tnved_cod
		FROM	@tab pfe   
				INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
					ON	pants.pants_id = pfe.pants_id   
				INNER JOIN	Products.TechSize ts
					ON	ts.ts_id = pants.ts_id   
				INNER JOIN	Products.ProdArticleNomenclature pan
					ON	pan.pan_id = pants.pan_id   
				INNER JOIN	Products.ProdArticle pa
					ON	pa.pa_id = pan.pa_id   
				INNER JOIN	Products.Sketch s
					ON	s.sketch_id = pa.sketch_id   
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = s.subject_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = pa.brand_id   
				OUTER APPLY (
				      	SELECT	TOP(1) c.consist_type_id
				      	FROM	Products.ProdArticleConsist pac   
				      			INNER JOIN	Products.Consist c
				      				ON	c.consist_id = pac.consist_id
				      	WHERE	pac.pa_id = pa.pa_id
				      	ORDER BY
				      		pac.percnt DESC
				      ) oa_ct
				LEFT JOIN	Products.TNVED_Settigs tnvds   
				INNER JOIN	Products.TNVED t
					ON	t.tnved_id = tnvds.tnved_id
					ON	tnvds.subject_id = s.subject_id
					AND	tnvds.ct_id = s.ct_id
					AND	tnvds.consist_type_id = oa_ct.consist_type_id
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