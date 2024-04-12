CREATE PROCEDURE [Synchro].[ProductsForEAN_GetForCreate]
	@fabricator_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	DECLARE @tab TABLE (pants_id INT, fabricator_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @lining_ao_id INT = 4
	
	BEGIN TRY
		;
		MERGE Synchro.ProductsForEANCnt t
		USING (
		      	SELECT	pfe.pants_id, pfe.fabricator_id 
		      	FROM	Synchro.ProductsForEAN pfe   
		      			LEFT JOIN	Synchro.ProductsForEANCnt pfec
		      				ON	pfec.pants_id = pfe.pants_id AND pfec.fabricator_id = pfe.fabricator_id
		      	WHERE	pfe.dt_create IS NULL
		      			AND	ISNULL(pfec.cnt_create, 0) < 10
		      ) s
				ON t.pants_id = s.pants_id AND  t.fabricator_id = s.fabricator_id
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
		     		dt_publish,
					fabricator_id
		     	)
		     VALUES
		     	(
		     		s.pants_id,
		     		1,
		     		0,
		     		@dt,
		     		@dt,
		     		@dt,
					s.fabricator_id
		     	) 
		     OUTPUT	INSERTED.pants_id,
					INSERTED.fabricator_id
		     INTO	@tab (
		     		pants_id,
					fabricator_id
		     	);	
		
		SELECT	pfe.pants_id,
				pfe.fabricator_id,
				b.brand_name,
				ISNULL(sj.subject_name_sf, sj.subject_name) subject_name,
				pa.sa + pan.sa sa,
				ts.ts_name,				
				ISNULL(t.tnved_cod, '6106200000') tnved_cod,
				sj.subject_gs1_id, 
				sj.block_gs1,
				ISNULL(k.gs1_id, '1200000002') kind_gs1_id,
				ISNULL(cr.color_name, 'безцветное') color_name,
				STUFF(oac.x, 1, 2, '') + CASE 
				                              WHEN oal.x IS NOT NULL THEN CHAR(10) + '  Подкладка: ' + STUFF(oal.x, 1, 2, '')
				                              ELSE ''
				                         END consists,
				CASE WHEN t.tnved_cod IS NULL THEN '6106' ELSE t2.tnved_cod END tnved_cod2,
				CASE WHEN t.tnved_cod IS NULL THEN '61' ELSE t3.tnved_cod END tnved_cod3,
				CASE WHEN t.tnved_cod IS NULL THEN '[60-70]' ELSE t4.tnved_cod END tnved_cod4,
				t5.tnved_cod tnved_cod5,
				t6.tnved_cod tnved_cod6
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
				LEFT JOIN Products.Kind k
					ON k.kind_id = s.kind_id	  
				INNER JOIN	Products.[Subject] sj
					ON	sj.subject_id = s.subject_id   
				INNER JOIN	Products.Brand b
					ON	b.brand_id = pa.brand_id   
				LEFT JOIN	Products.ProdArticleNomenclatureColor panc   
				LEFT JOIN	Products.Color cr
					ON	cr.color_cod = panc.color_cod
					ON	panc.pan_id = pan.pan_id
					AND	panc.is_main = 1   
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
				LEFT JOIN Products.TNVED t2
					ON t2.tnved_id = t.tnved_pid
				LEFT JOIN Products.TNVED t3
					ON t3.tnved_id = t2.tnved_pid
				LEFT JOIN Products.TNVED t4
					ON t4.tnved_id = t3.tnved_pid
				LEFT JOIN Products.TNVED t5
					ON t5.tnved_id = t4.tnved_pid
				LEFT JOIN Products.TNVED t6
					ON t6.tnved_id = t5.tnved_pid
				OUTER APPLY (
				      	SELECT	', ' + c.consist_name + ' ' + CASE 
				      	      	                                   WHEN ISNULL(pac.percnt, 0) = 0 THEN ''
				      	      	                                   ELSE CAST(pac.percnt AS VARCHAR(10)) + '%'
				      	      	                              END
				      	FROM	Products.ProdArticleConsist pac   
				      			INNER JOIN	Products.Consist AS c
				      				ON	c.consist_id = pac.consist_id
				      	WHERE	pac.pa_id = pa.pa_id
				      	FOR XML	PATH('')
				      ) oac(x)
				OUTER APPLY (
				                    	SELECT	', ' + ao.ao_name + ' ' + CASE 
				                    	      	                               WHEN ISNULL(paao.ao_value, 0) = 0 THEN ''
				                    	      	                               ELSE CAST(CAST(paao.ao_value AS INT) AS VARCHAR(10)) + '%'
				                    	      	                          END
				                    	FROM	Products.ProdArticleAddedOption paao   
				                    			INNER JOIN	Products.AddedOption AS ao
				                    				ON	ao.ao_id = paao.ao_id
				                    	WHERE	paao.pa_id = pa.pa_id
				                    			AND	ao.ao_id_parent = @lining_ao_id
				                    			AND	ao.ao_id != 26
				                    	FOR XML	PATH('')
				                    )oal(x)
			WHERE @fabricator_id IS NULL
			OR	pfe.fabricator_id = @fabricator_id
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
		--WITH LOG;
	END CATCH
GO