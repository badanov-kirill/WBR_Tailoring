CREATE PROCEDURE [Products].[ProdArticleCard_Save]
	@sketch_id INT,
	@employee_id INT,
	@xml_data XML,
	@rv_bigint VARCHAR(19) = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @state_constructor_take_job_add TINYINT = 9 --Взят в работу конструктором
	DECLARE @state_constructor_take_job_add_rework TINYINT = 15 --Взят на доработку конструктором
	DECLARE @dt dbo.SECONDSTIME = GETDATE()
	DECLARE @model_art_color TABLE(rn INT, sa_nm VARCHAR(36), color_cod INT, is_main BIT, PRIMARY KEY CLUSTERED(rn, sa_nm, color_cod))
	DECLARE @model_art_ts TABLE(rn INT, sa_nm VARCHAR(36), ts_id INT, PRIMARY KEY CLUSTERED(rn, sa_nm, ts_id))
	DECLARE @consist_tab TABLE(rn INT, consist_id INT, percnt TINYINT, PRIMARY KEY CLUSTERED(rn, consist_id))
	DECLARE @ao_model TABLE (rn INT, ao_id INT, val DECIMAL(9, 2), si_id INT, PRIMARY KEY CLUSTERED(rn, ao_id))
	DECLARE @ao_ozon TABLE (rn INT, attribute_id BIGINT, av_id BIGINT, val VARCHAR(50), PRIMARY KEY(rn, attribute_id, av_id))
	DECLARE @ct_id INT 
	DECLARE @subject_id INT
	DECLARE @consist_type_id INT 
	DECLARE @prod_article_nomenclature_output TABLE (
	        	pan_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	pa_id INT,
	        	sa VARCHAR(36),
	        	is_deleted BIT,
	        	nm_id INT,
	        	whprice DECIMAL(9, 2) NULL,
	        	price_ru DECIMAL(9, 2) NULL,
	        	cutting_degree_difficulty DECIMAL(4, 2) NULL
	        )
	
	DECLARE @rv ROWVERSION = CAST(CAST(@rv_bigint AS BIGINT) AS ROWVERSION)
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @with_log BIT = 1
	DECLARE @sa VARCHAR(15)
	
	DECLARE @sketch_output TABLE 
	        (rv_bigint BIGINT)
	
	DECLARE @prod_aricle_output TABLE 
	        (
	        	pa_id INT PRIMARY KEY CLUSTERED NOT NULL,
	        	sketch_id INT NOT NULL,
	        	is_deleted BIT NOT NULL,
	        	model_number INT NOT NULL,
	        	descr VARCHAR(1000) NULL,
	        	brand_id INT NOT NULL,
	        	season_id INT NULL,
	        	collection_id INT NULL,
	        	style_id INT NULL,
	        	direction_id INT NULL,
	        	employee_id INT NOT NULL,
	        	dt dbo.SECONDSTIME NOT NULL,
	        	rn INT,
	        	ao_ts_id INT,
	        	is_not_new BIT
	        )        	
	
	DECLARE @model_tab TABLE(
	        	pa_id INT,
	        	is_deleted BIT,
	        	descr VARCHAR(1000),
	        	brand_id INT,
	        	season_id INT,
	        	collection_id INT,
	        	style_id INT,
	        	direction_id INT,
	        	art_color_xml XML,
	        	consist_xml XML,
	        	ao_xml XML,
	        	ao_ozon_xml XML,
	        	rn INT,
	        	ao_ts_id INT,
	        	is_not_new BIT,
	        	art_ts_xml XML,
	        	cut_comment VARCHAR(200),
	        	sew_comment VARCHAR(200)
	        )
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с номером ' + CAST(v.sketch_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN s.rv != @rv THEN 'Этот эскиз уже отреадактировал сотрудник с кодом' + CAST(s.employee_id AS VARCHAR(10)) + ' ' + CONVERT(VARCHAR(20), s.dt, 121) 
	      	                        +
	      	                        ', перечитайте данные и сохраните снова'
	      	                   ELSE NULL
	      	              END,
			@sa = s.sa,
			@ct_id = s.ct_id,
			@subject_id = s.subject_id
	FROM	(VALUES(@sketch_id))v(sketch_id)   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = v.sketch_id   
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @model_tab
	  (
	    pa_id,
	    is_deleted,
	    descr,
	    brand_id,
	    season_id,
	    collection_id,
	    style_id,
	    direction_id,
	    art_color_xml,
	    consist_xml,
	    ao_xml,
	    ao_ozon_xml,
	    rn,
	    ao_ts_id,
	    is_not_new,
	    art_ts_xml,
	    cut_comment,
	    sew_comment
	  )
	SELECT	ml.value('@id', 'int')         pa_id,
			ml.value('@del', 'bit')        is_deleted,
			ml.value('@descr', 'varchar(1000)') descr,
			ml.value('@brand', 'int')      brand_id,
			ml.value('@season', 'int')     season_id,
			ml.value('@collection', 'int') collection_id,
			ml.value('@style', 'int')      style_id,
			ml.value('@direction', 'int') direction_id,
			ml.query('arts')               art_color_xml,
			ml.query('cons')               consist_xml,
			ml.query('aos')                ao_xml,
			ml.query('aos_ozon')           ao_ozon_xml,
			ROW_NUMBER() OVER(ORDER BY ml.value('@id', 'int')) rn,
			ml.value('@aots', 'int')       ao_ts_id,
			ISNULL(ml.value('@nonew', 'bit'), 0) is_not_new,
			ml.query('tarts')              art_ts_xml,
			ml.value('@cutc', 'varchar(200)') cut_comment,
			ml.value('@sewc', 'varchar(200)') sew_comment
	FROM	@xml_data.nodes('models/model')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN mt.pa_id IS NOT NULL AND pa.pa_id IS NULL THEN 'У модели в строчке ' + CAST(mt.rn AS VARCHAR(10)) +
	      	                        ' указан не существующий идентификатор ' + CAST(mt.pa_id AS VARCHAR(10))
	      	                   WHEN b.brand_id IS NULL THEN 'У модели в строчке ' + CAST(mt.rn AS VARCHAR(10)) + ' указан не существующий' + CAST(mt.brand_id AS VARCHAR(10)) 
	      	                        + ' идентификатор бренда'
	      	                   ELSE NULL
	      	              END
	FROM	@model_tab mt   
			LEFT JOIN	Products.ProdArticle pa
				ON	pa.pa_id = mt.pa_id   
			LEFT JOIN	Products.Brand b
				ON	mt.brand_id = b.brand_id			
	WHERE	(mt.pa_id IS NOT NULL AND pa.pa_id IS NULL)
			OR	b.brand_id IS NULL
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @model_art_color
	  (
	    sa_nm,
	    color_cod,
	    is_main,
	    rn
	  )
	SELECT	ml.value('@sanm', 'varchar(36)'),
			ml.value('@cid', 'int'),
			ml.value('@m', 'bit'),
			mt.rn
	FROM	@model_tab mt   
			CROSS APPLY mt.art_color_xml.nodes('arts/art')x(ml)	
	
	INSERT INTO @model_art_ts
	  (
	    sa_nm,
	    ts_id,
	    rn
	  )
	SELECT	ml.value('@sanm', 'varchar(36)'),
			ml.value('@id', 'int'),
			mt.rn
	FROM	@model_tab mt   
			CROSS APPLY mt.art_ts_xml.nodes('tarts/tart')x(ml)	
	
	SELECT	@error_text = CASE 
	      	                   WHEN sts.ts_id IS NULL THEN 'У артикула ' + mts.sa_nm + '  есть размер ' + ts.ts_name + ', которого нет у эскиза '
	      	                   WHEN sts.ts_id IS NOT NULL AND s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) AND spp.ts_id IS NULL THEN 
	      	                        'У артикула есть размеры без периметров'
	      	                   ELSE NULL
	      	              END
	FROM	@model_tab mt   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = @sketch_id   
			INNER JOIN	@model_art_ts mts
				ON	mts.rn = mt.rn 
			INNER JOIN Products.TechSize ts
				ON ts.ts_id = mts.ts_id  
			LEFT JOIN	Products.SketchPatternPerimetr spp
				ON	spp.sketch_id = s.sketch_id
				AND	spp.ts_id = mts.ts_id   
			LEFT JOIN	Products.SketchTechSize sts
				ON	sts.sketch_id = s.sketch_id
				AND	sts.ts_id = mts.ts_id
	WHERE	sts.ts_id IS NULL
			OR	(s.ss_id NOT IN (@state_constructor_take_job_add, @state_constructor_take_job_add_rework) AND spp.ts_id IS NULL)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @consist_tab
	  (
	    consist_id,
	    percnt,
	    rn
	  )
	SELECT	ml.value('@id', 'int'),
			ml.value('@per', 'tinyint'),
			mt.rn
	FROM	@model_tab mt   
			CROSS APPLY mt.consist_xml.nodes('cons/con')x(ml)
	
	INSERT INTO @ao_model
	  (
	    rn,
	    ao_id,
	    val,
	    si_id
	  )
	SELECT	mt.rn,
			ml.value('@id', 'int'),
			CASE 
			     WHEN ml.value('@val', 'decimal(9,2)') = 0 THEN NULL
			     ELSE ml.value('@val', 'decimal(9,2)')
			END,
			ml.value('@si', 'int')
	FROM	@model_tab mt   
			CROSS APPLY mt.ao_xml.nodes('aos/ao')x(ml)	
		
	INSERT INTO @ao_ozon
		(
			rn,
			attribute_id,
			av_id,
			val
		)
	SELECT	mt.rn,
			ml.value('@id', 'bigint'),
			ISNULL(ml.value('@av_id', 'bigint'), 0),
			CASE 
			     WHEN ml.value('@val', 'varchar(50)') = '' THEN NULL
			     ELSE ml.value('@val', 'varchar(50)')
			END
	FROM	@model_tab mt   
			CROSS APPLY mt.ao_ozon_xml.nodes('aos_ozon/attr')x(ml)
			
	SET @consist_type_id = (
	    	SELECT	TOP(1) c.consist_type_id
	    	FROM	@consist_tab ct   
	    			INNER JOIN	Products.Consist c
	    				ON	c.consist_id = ct.consist_id
	    	ORDER BY
	    		ct.percnt DESC
	)
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.TNVED_Settigs ts
	   	WHERE	ts.subject_id = @subject_id
	   			AND	ts.ct_id = @ct_id
	   			AND	ts.consist_type_id = @consist_type_id
	)
	BEGIN
		RAISERROR('Не удалось определить код ТНВД, обратитесь к руководителю',16,1)
		RETURN
	END
	
	IF EXISTS(SELECT ct.rn  FROM @consist_tab ct GROUP BY ct.rn HAVING SUM(ct.percnt) != 100) 
	BEGIN
		RAISERROR('Сумма процентов состава должна быть равна 100',16,1)
		RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		UPDATE	Products.Sketch
		SET 	employee_id = @employee_id,
				dt = @dt				
				OUTPUT	CAST(INSERTED.rv AS BIGINT) rv_bigint
				INTO	@sketch_output (
						rv_bigint
					)
		WHERE	sketch_id = @sketch_id
				AND	rv = @rv
		
		IF @@ROWCOUNT = 0
		BEGIN
		    SET @with_log = 0
		    RAISERROR('Кто то уже отредактировал данные, перечитайте и попробуйте снова', 16, 1)
		    RETURN
		END
		
		SELECT	@rv_bigint = so.rv_bigint
		FROM	@sketch_output so 
		
		;
		MERGE Products.ProdArticle t
		USING (
		      	SELECT	mt.pa_id,
		      			@sketch_id       sketch_id,
		      			mt.is_deleted,
		      			mt.descr,
		      			mt.brand_id,
		      			mt.season_id,
		      			mt.collection_id,
		      			mt.style_id,
		      			mt.direction_id,
		      			@employee_id     employee_id,
		      			@dt              dt,
		      			(ISNULL(oa_mn.model_number, 0) + mt.rn) model_number,
		      			mt.rn,
		      			mt.ao_ts_id,
		      			mt.is_not_new,
		      			mt.cut_comment,
		      			mt.sew_comment
		      	FROM	@model_tab mt   
		      			OUTER APPLY (
		      			      	SELECT	MAX(pa.model_number) model_number
		      			      	FROM	Products.ProdArticle pa
		      			      	WHERE	pa.sketch_id = @sketch_id
		      			      )          oa_mn
		      ) s
				ON t.pa_id = s.pa_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	is_deleted        = s.is_deleted,
		     		descr             = s.descr,
		     		collection_id     = s.collection_id,
		     		style_id          = s.style_id,
		     		employee_id       = s.employee_id,
		     		direction_id      = s.direction_id,
		     		dt                = s.dt,
		     		season_id         = s.season_id,
		     		ao_ts_id          = s.ao_ts_id,
		     		is_not_new        = s.is_not_new,
		     		cut_comment       = s.cut_comment,
		     		sew_comment       = s.sew_comment
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		sketch_id,
		     		is_deleted,
		     		model_number,
		     		descr,
		     		brand_id,
		     		season_id,
		     		collection_id,
		     		style_id,
		     		direction_id,
		     		create_employee_id,
		     		create_dt,
		     		employee_id,
		     		dt,
		     		ao_ts_id,
		     		is_not_new,
		     		sa,
		     		cut_comment,
		     		sew_comment
		     	)
		     VALUES
		     	(
		     		s.sketch_id,
		     		s.is_deleted,
		     		s.model_number,
		     		s.descr,
		     		s.brand_id,
		     		s.season_id,
		     		s.collection_id,
		     		s.style_id,
		     		s.direction_id,
		     		s.employee_id,
		     		s.dt,
		     		s.employee_id,
		     		s.dt,
		     		s.ao_ts_id,
		     		s.is_not_new,
		     		@sa + CAST(s.model_number AS VARCHAR(10)) + '/',
		     		s.cut_comment,
		     		s.sew_comment
		     	)
		     OUTPUT	INSERTED.pa_id,
		     		INSERTED.sketch_id,
		     		INSERTED.is_deleted,
		     		INSERTED.model_number,
		     		INSERTED.brand_id,
		     		INSERTED.season_id,
		     		INSERTED.collection_id,
		     		INSERTED.style_id,
		     		INSERTED.direction_id,
		     		INSERTED.employee_id,
		     		INSERTED.dt,
		     		s.rn,
		     		INSERTED.ao_ts_id,
		     		INSERTED.is_not_new
		     INTO	@prod_aricle_output (
		     		pa_id,
		     		sketch_id,
		     		is_deleted,
		     		model_number,
		     		brand_id,
		     		season_id,
		     		collection_id,
		     		style_id,
		     		direction_id,
		     		employee_id,
		     		dt,
		     		rn,
		     		ao_ts_id,
		     		is_not_new
		     	);
		
		INSERT INTO History.ProdArticle
		  (
		    pa_id,
		    sketch_id,
		    is_deleted,
		    model_number,
		    brand_id,
		    season_id,
		    collection_id,
		    style_id,
		    direction_id,
		    employee_id,
		    dt,
		    ao_ts_id,
		    is_not_new
		  )
		SELECT	pao.pa_id,
				pao.sketch_id,
				pao.is_deleted,
				pao.model_number,
				pao.brand_id,
				pao.season_id,
				pao.collection_id,
				pao.style_id,
				pao.direction_id,
				pao.employee_id,
				pao.dt,
				pao.ao_ts_id,
				pao.is_not_new
		FROM	@prod_aricle_output pao;
		
		WITH cte_Target AS
		(
			SELECT	paao.pa_id,
					paao.ao_id,
					paao.employee_id,
					paao.dt,
					paao.ao_value,
					paao.si_id
			FROM	Products.ProdArticleAddedOption paao
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@prod_aricle_output pao
			     		WHERE	pao.pa_id = paao.pa_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	pao.pa_id,
		      			aom.ao_id,
		      			@employee_id     employee_id,
		      			@dt              dt,
		      			aom.val          ao_value,
		      			aom.si_id
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@ao_model aom
		      				ON	pao.rn = aom.rn
		      ) s
				ON t.ao_id = s.ao_id
				AND t.pa_id = s.pa_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	employee_id     = s.employee_id,
		     		dt              = s.dt,
		     		ao_value        = s.ao_value,
		     		si_id           = s.si_id
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pa_id,
		     		ao_id,
		     		employee_id,
		     		dt,
		     		ao_value,
		     		si_id
		     	)
		     VALUES
		     	(
		     		s.pa_id,
		     		s.ao_id,
		     		s.employee_id,
		     		s.dt,
		     		s.ao_value,
		     		s.si_id
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_Target AS
		(
			SELECT	paav.pa_id,
					paav.attribute_id,
					paav.av_id,
					paav.employee_id,
					paav.dt
			FROM	Ozon.ProdArticleAttributeValues paav
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@prod_aricle_output pao
			     		WHERE	pao.pa_id = paav.pa_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	pao.pa_id,
		      			aom.attribute_id,
		      			aom.av_id,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@ao_ozon aom
		      				ON	pao.rn = aom.rn
		      	WHERE aom.av_id != 0
		      ) s
				ON t.av_id = s.av_id
				AND t.attribute_id = s.attribute_id
				AND t.pa_id = s.pa_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pa_id,
					attribute_id,
					av_id,
					employee_id,
					dt
		     	)
		     VALUES
		     	(
		     		s.pa_id,
					s.attribute_id,
					s.av_id,
					s.employee_id,
					s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		     
		WITH cte_Target AS
		(
			SELECT	paa.pa_id,
					paa.attribute_id,
					paa.attribute_value,
					paa.employee_id,
					paa.dt
			FROM	Ozon.ProdArticleAttribute paa
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@prod_aricle_output pao
			     		WHERE	pao.pa_id = paa.pa_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	pao.pa_id,
		      			aom.attribute_id,
		      			aom.val,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@ao_ozon aom
		      				ON	pao.rn = aom.rn
		      	WHERE aom.av_id = 0 AND aom.val != ''
		      ) s
				ON t.attribute_id = s.attribute_id
				AND t.pa_id = s.pa_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	attribute_value = s.val,
					employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pa_id,
					attribute_id,
					attribute_value,
					employee_id,
					dt
		     	)
		     VALUES
		     	(
		     		s.pa_id,
					s.attribute_id,
					s.val,
					s.employee_id,
					s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_Target AS
		(
			SELECT	pan.pan_id,
					pan.pa_id,
					pan.sa,
					pan.is_deleted,
					pan.employee_id,
					pan.dt,
					pan.nm_id,
					pan.whprice,
					pan.price_ru,
					pan.cutting_degree_difficulty
			FROM	Products.ProdArticleNomenclature pan
			WHERE	EXISTS (
			     		SELECT	1
			     		FROM	@prod_aricle_output pao
			     		WHERE	pao.pa_id = pan.pa_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	DISTINCT pao.pa_id,
		      			mac.sa_nm        sa,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@model_art_color mac
		      				ON	mac.rn = pao.rn
		      ) s
				ON t.pa_id = s.pa_id
				AND t.sa = s.sa
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	is_deleted      = 0,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pa_id,
		     		sa,
		     		is_deleted,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.pa_id,
		     		s.sa,
		     		0,
		     		s.employee_id,
		     		s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.nm_id IS NULL THEN 
		     UPDATE	
		     SET 	is_deleted      = 1,
		     		employee_id     = @employee_id,
		     		dt              = @dt
		     		OUTPUT	INSERTED.pan_id,
		     				INSERTED.pa_id,
		     				INSERTED.sa,
		     				INSERTED.is_deleted,
		     				INSERTED.nm_id,
		     				INSERTED.whprice,
		     				INSERTED.price_ru,
		     				INSERTED.cutting_degree_difficulty
		     		INTO	@prod_article_nomenclature_output (
		     				pan_id,
		     				pa_id,
		     				sa,
		     				is_deleted,
		     				nm_id,
		     				whprice,
		     				price_ru,
		     				cutting_degree_difficulty
		     			); 
		
		WITH cte_Target AS
		(
			SELECT	panc.pan_id,
					panc.color_cod,
					panc.is_main,
					panc.employee_id,
					panc.dt
			FROM	Products.ProdArticleNomenclatureColor panc
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@prod_article_nomenclature_output pano
			     		WHERE	pano.pan_id = panc.pan_id
			     	)
		)  
		MERGE cte_Target t
		USING (
		      	SELECT	pano.pan_id,
		      			mac.color_cod,
		      			mac.is_main,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@model_art_color mac
		      				ON	mac.rn = pao.rn   
		      			INNER JOIN	@prod_article_nomenclature_output pano
		      				ON	pano.pa_id = pao.pa_id
		      				AND	mac.sa_nm = pano.sa
		      ) s
				ON t.pan_id = s.pan_id
				AND t.color_cod = s.color_cod
		WHEN MATCHED AND t.is_main != s.is_main THEN 
		     UPDATE	
		     SET 	is_main         = s.is_main,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pan_id,
		     		color_cod,
		     		is_main,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.pan_id,
		     		s.color_cod,
		     		s.is_main,
		     		s.employee_id,
		     		s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		
		WITH cte_Target AS
		(
			SELECT	pants.pants_id,
					pants.pan_id,
					pants.ts_id,
					pants.is_deleted,
					pants.employee_id,
					pants.dt,
					pan.nm_id
			FROM	Products.ProdArticleNomenclatureTechSize pants   
					LEFT JOIN	@prod_article_nomenclature_output pan
						ON	pan.pan_id = pants.pan_id
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@prod_article_nomenclature_output pano
			     		WHERE	pano.pan_id = pants.pan_id
			     	)
		)  
		MERGE cte_Target t
		USING (
		      	SELECT	pano.pan_id,
		      			mats.ts_id,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@prod_aricle_output pao   
		      			INNER JOIN	@model_art_ts mats
		      				ON	mats.rn = pao.rn   
		      			INNER JOIN	@prod_article_nomenclature_output pano
		      				ON	pano.pa_id = pao.pa_id
		      				AND	mats.sa_nm = pano.sa
		      ) 
		      s
				ON t.pan_id = s.pan_id
				AND t.ts_id = s.ts_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	is_deleted      = 0,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pan_id,
		     		ts_id,
		     		is_deleted,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.pan_id,
		     		s.ts_id,
		     		0,
		     		s.employee_id,
		     		s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE AND t.nm_id IS NULL THEN 
		     UPDATE	
		     SET 	is_deleted      = 1,
		     		employee_id     = @employee_id,
		     		dt              = @dt;
		
		WITH cte_Target AS
		(
			SELECT	pac.pa_id,
					pac.consist_id,
					pac.percnt,
					pac.employee_id,
					pac.dt
			FROM	Products.ProdArticleConsist pac
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@prod_aricle_output pao
			     		WHERE	pao.pa_id = pac.pa_id
			     	)
		)
		MERGE cte_Target t
		USING (
		      	SELECT	pao.pa_id,
		      			ct.consist_id,
		      			ct.percnt,
		      			@employee_id     employee_id,
		      			@dt              dt
		      	FROM	@consist_tab ct   
		      			INNER JOIN	@prod_aricle_output pao
		      				ON	pao.rn = ct.rn
		      ) s
				ON t.pa_id = s.pa_id
				AND t.consist_id = s.consist_id
		WHEN MATCHED AND t.percnt != s.percnt THEN 
		     UPDATE	
		     SET 	percnt          = s.percnt,
		     		employee_id     = s.employee_id,
		     		dt              = s.dt
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		pa_id,
		     		consist_id,
		     		percnt,
		     		employee_id,
		     		dt
		     	)
		     VALUES
		     	(
		     		s.pa_id,
		     		s.consist_id,
		     		s.percnt,
		     		s.employee_id,
		     		s.dt
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	; 
		
		INSERT INTO History.ProdArticleNomenclature
		  (
		    pan_id,
		    pa_id,
		    sa,
		    is_deleted,
		    employee_id,
		    dt,
		    nm_id,
		    whprice,
		    price_ru,
		    cutting_degree_difficulty
		  )
		SELECT	pano.pan_id,
				pano.pa_id,
				pano.sa,
				pano.is_deleted,
				@employee_id,
				@dt,
				pano.nm_id,
				pano.whprice,
				pano.price_ru,
				pano.cutting_degree_difficulty
		FROM	@prod_article_nomenclature_output pano
		
		COMMIT TRANSACTION
		
		SELECT	@sketch_id     sketch_id,
				@rv_bigint     rv_bigint
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
		
		IF @with_log = 1
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
		END
		ELSE
		BEGIN
		    RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess)
		END
	END CATCH 