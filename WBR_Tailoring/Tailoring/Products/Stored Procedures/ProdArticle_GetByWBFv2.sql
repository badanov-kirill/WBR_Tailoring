--exec [Products].[ProdArticle_GetByWBFv2] 11512, 1
CREATE PROCEDURE [Products].[ProdArticle_GetByWBFv2]
	@pa_id INT,
	@fabricator_id INT,
	@for_upd BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET XACT_ABORT ON
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleNomenclature pan   
	   			LEFT JOIN	Products.ProdArticleNomenclatureTechSize pants
	   				ON	pants.pan_id = pan.pan_id
	   	WHERE	pan.pa_id = @pa_id
	   			AND	pants.pan_id IS NULL
	   			AND pants.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Есть цвет без размеров', 16, 1)
	    RETURN
	END
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleNomenclature pan   
	   	WHERE	pan.pa_id = @pa_id
	   			AND	ISNULL(pan.price_ru, 0) = 0
	   			AND pan.is_deleted = 0
	   )
	BEGIN
	    RAISERROR('Есть цвет без цены', 16, 1)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Products.ProdArticleConsist pac
	   	WHERE	pac.pa_id = @pa_id
	   )
	BEGIN
	    RAISERROR('Не указан состав', 16, 1)
	    RETURN
	END
	
	DECLARE @tab TABLE (pan_id INT)
	DECLARE @dt DATETIME2(0) = GETDATE()

	BEGIN TRY
	
	;
	MERGE Wildberries.ProdArticleForWBCnt t
	USING (
	      	SELECT	@pa_id pa_id,
					@fabricator_id
	      ) s(pa_id, fabricator_id)
			ON s.pa_id = t.pa_id
				AND s.fabricator_id = t.fabricator_id
	WHEN MATCHED THEN 
	     UPDATE	
	     SET 	cnt_save     = cnt_save + 1,
	     		dt_save      = @dt
	WHEN NOT MATCHED THEN 
	     INSERT
	     	(
	     		pa_id,
	     		cnt_save,
	     		dt,
	     		dt_save,
	     		cnt_load, 
	     		dt_load,
				fabricator_id
	     	)
	     VALUES
	     	(
	     		@pa_id,
	     		1,
	     		@dt,
	     		@dt,
	     		0,
	     		@dt,
				@fabricator_id
	     	);
	--0
	SELECT	pa.pa_id,
			ISNULL(pa.descr, s.descr)     descr,
			CASE WHEN LEFT(b.brand_name, 1) = '&' THEN REPLACE(b.brand_name, '&' , 'And') ELSE  b.brand_name END brand_name,
			ISNULL(sn.season_name, sn2.season_name) season_name,
			cl.collection_name,
			ISNULL(st.style_name, st2.style_name) style_name,
			ISNULL(d.direction_name, d2.direction_name) direction_name,
			sj.subject_name,
			k.kind_name,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') sa_imt,
			STUFF(con.x, 1, 1, '')        contents,
			tsz.rus_name                   ao_ts_name,
			t.tnved_cod,
			t.tnved_id,
			case 
				when sd.declaration_type_id = 1 then sd.declaration_number 
				else null
			end  declaration_name,
			case 
				when sd.declaration_type_id = 2 then sd.declaration_number 
				else null
			end  certificate_name,
			sd.start_date,
			sd.end_date,
			s.ct_id,
			oa_ct.consist_type_id,
			'Россия' country_name,
			kw.key_word,
			LOWER(dbo.bin2uid(pafw.imt_uid)) imt_uid, 
			pafw.imt_id,
			pafw.fabricator_id,
			case 
				when f.taxation = 0  then '0'
				when f.taxation = 1  then k.tax
			end tax
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id 
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			LEFT JOIN	Products.Season sn
				ON	sn.season_id = pa.season_id   
			INNER JOIN	Products.Season sn2
				ON	sn2.season_id = s.season_id   
			LEFT JOIN	Products.[Collection] cl
				ON	cl.collection_id = pa.collection_id   
			LEFT JOIN	Products.Style st
				ON	st.style_id = pa.style_id   
			LEFT JOIN	Products.Style st2
				ON	st2.style_id = s.style_id   
			LEFT JOIN	Products.Direction d
				ON	d.direction_id = pa.direction_id   
			LEFT JOIN	Products.Direction d2
				ON	d2.direction_id = s.direction_id   
			LEFT JOIN	Products.Kind k
				ON	k.kind_id = s.kind_id   
			LEFT JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			LEFT JOIN	Products.TechSize tsz
				ON	tsz.ts_id = pa.ao_ts_id 
			LEFT JOIN Products.KeyWords kw
				ON kw.kw_id = s.kw_id  
			LEFT JOIN Wildberries.ProdArticleForWB pafw
				ON pafw.pa_id = pa.pa_id AND pafw.fabricator_id = @fabricator_id 
			LEFT JOIN Settings.Fabricators f
				ON f.fabricator_id = pafw.fabricator_id
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
				ON	tnvds.subject_id = s.subject_id
				AND	tnvds.ct_id = s.ct_id
				AND	tnvds.consist_type_id = oa_ct.consist_type_id   
			LEFT JOIN	Products.TNVED t
				ON	t.tnved_id = tnvds.tnved_id 
			LEFT JOIN Settings.Declarations_TNVED dt
				ON dt.tnved_id = t.tnved_id
			LEFT JOIN  Settings.Declarations sd
				ON sd.declaration_id = dt.declaration_id
					AND GETDATE() between sd.start_date and sd.end_date
			OUTER APPLY (
			      	SELECT	';' + c.contents_name
			      	FROM	Products.SketchContent sc   
			      			INNER JOIN	Products.[Content] c
			      				ON	c.contents_id = sc.contents_id
			      	WHERE	sc.sketch_id = s.sketch_id
			      	FOR XML	PATH('')
			      ) con(x)
	WHERE	pa.pa_id = @pa_id
			
	--1
	SELECT	pan.pan_id,
			pan.nm_id,
			pan.sa,
			mc.color_name main_color,
			STUFF(artcol.x, 1, 1, '') not_nain_colors,
			pan.whprice,
			pan.price_ru,
			LOWER(dbo.bin2uid(panfw.wb_uid)) nm_uid
	FROM	Products.ProdArticleNomenclature pan 
			LEFT JOIN Products.ProdArticleNomenclatureColor pancm
				ON pancm.pan_id = pan.pan_id AND pancm.is_main = 1
			LEFT JOIN Products.Color mc
				ON mc.color_cod = pancm.color_cod	
			LEFT JOIN Wildberries.ProdArticleNomenclatureForWB panfw
				ON panfw.pan_id = pan.pan_id		  
			OUTER APPLY (
			      	SELECT	';' + c.color_name
			      	FROM	Products.ProdArticleNomenclatureColor panc   
			      			INNER JOIN	Products.Color c
			      				ON	c.color_cod = panc.color_cod
			      	WHERE	panc.pan_id = pan.pan_id
			      	AND panc.is_main = 0
			      	FOR XML	PATH('')
			      ) artcol(x)
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0
			AND ISNULL(pan.price_ru, 0) > 0 	
			AND ((@for_upd = 0 
							AND pan.nm_id IS NULL 
							AND NOT EXISTS(
			              	SELECT	1
			              	FROM	Wildberries.ProdArticleNomenclatureForWB panfw
			              	WHERE	panfw.pan_id = pan.pan_id AND panfw.fabricator_id = @fabricator_id 
							)) OR @for_upd = 1) 
	
	--2
	SELECT	pan.pan_id,
			ts.rus_name ts_name,
			e.ean,
			pantw.chrt_id, 
			LOWER(dbo.bin2uid(pantw.wb_uid)) chrt_uid
	FROM	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
			LEFT JOIN Wildberries.ProdArticleNomenclatureTSForWB pantw
				ON pantw.pants_id = e.pants_id 
	WHERE	pan.pa_id = @pa_id
			AND	pan.is_deleted = 0	 
			AND pants.is_deleted = 0 
	--3
	SELECT	c.consist_name,
			pac.percnt
	FROM	Products.ProdArticleConsist pac   
			INNER JOIN	Products.Consist c
				ON	c.consist_id = pac.consist_id
	WHERE	pac.pa_id = @pa_id
	ORDER BY
		pac.percnt DESC 
	
	--4 
	SELECT	MAX(v.pname) pname,
			string_agg(v.val, ';') val,	
			MAX(v.required_mode) required_mode
	FROM	(SELECT	aop.ao_name as pname,
    	 			ao.ao_name as val,
   				    ao.ao_id,
					aop.ao_id as aop_id,
    	 			ISNULL(oa.required_mode, 0) required_mode,
    	 			ROW_NUMBER() OVER(PARTITION BY aop.ao_name ORDER BY ao.ao_id) rn
    		 FROM	Products.ProdArticle pa   
    	 			INNER JOIN	Products.Sketch s
    	 				ON	s.sketch_id = pa.sketch_id   
    	 			INNER JOIN	Products.ProdArticleAddedOption paao
    	 				ON	paao.pa_id = pa.pa_id   
    	 			INNER JOIN	Products.AddedOption ao
    	 				ON	ao.ao_id = paao.ao_id   
    	 			LEFT JOIN	Products.AddedOption aop
    	 				ON	aop.ao_id = ao.ao_id_parent    
    	 			OUTER APPLY (
    	 		      		SELECT	TOP(1) sao.required_mode
    	 		      		FROM	Products.SubjectAddedOption sao
    	 		      		WHERE	sao.subject_id = s.subject_id
    	 		      				AND	sao.ao_id = aop.ao_id
    	 				  )         oa
    		 WHERE	pa.pa_id = @pa_id
    	 			AND	ao.content_id IS NOT NULL
    	 			AND	ao.isdeleted = 0
    	 			AND	(ao.ao_id_parent != 7 OR ao.ao_id_parent IS NULL)
					AND EXISTS (SELECT NULL FROM Products.SubjectAddedOption sao WHERE sao.subject_id = s.subject_id AND sao.ao_id = paao.ao_id)
					AND aop.ao_name  is not null
	)v
	WHERE 
		(v.aop_id = 671 and v.rn =1) --Декоративные элементы
		or (v.aop_id = 200 and v.rn =1) --Назначение
		or (v.aop_id not in (671, 200)and v.rn < 4)
	GROUP BY
		v.pname
	
	--5
	SELECT ao.ao_name as pname,
	ao.ao_id,
    case
		when ao.ao_id in (1337,1338,1339) then ROUND(paao.ao_value,0)  --Ширина упаковки, Высота упаковки, Длина упаковки
		else paao.ao_value
	end as val,
    		ISNULL(oa.required_mode, 0) required_mode   	 			
		FROM	Products.ProdArticle pa   
    		INNER JOIN	Products.Sketch s
    	 		ON	s.sketch_id = pa.sketch_id   
    		INNER JOIN	Products.ProdArticleAddedOption paao
    	 		ON	paao.pa_id = pa.pa_id   
    		INNER JOIN	Products.AddedOption ao
    	 		ON	ao.ao_id = paao.ao_id      
    		OUTER APPLY (
    	 			SELECT	TOP(1) sao.required_mode
    	 			FROM	Products.SubjectAddedOption sao
    	 			WHERE	sao.subject_id = s.subject_id
    	 		      		AND	sao.ao_id = ao.ao_id
    	 			)         oa
		WHERE	pa.pa_id = @pa_id
    		AND	ao.content_id IS NOT NULL
    		AND	ao.isdeleted = 0
    		AND	(ao.ao_id_parent != 7 OR ao.ao_id_parent IS NULL)
			AND EXISTS (SELECT NULL FROM Products.SubjectAddedOption sao WHERE sao.subject_id = s.subject_id AND sao.ao_id = paao.ao_id)
			AND ao.ao_id_parent  is null

	
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