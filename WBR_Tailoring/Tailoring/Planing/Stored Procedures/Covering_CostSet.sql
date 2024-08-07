﻿CREATE PROCEDURE [Planing].[Covering_CostSet]
	@covering_id INT,
	@spcv_xml XML,
	@sketch_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_tab TABLE (spcv_id INT, pan_id INT, cost_rm DECIMAL(9, 2), cost_work DECIMAL(9, 2), cost_fix DECIMAL(9, 2), cost_add DECIMAL(9, 2), price_ru DECIMAL(9, 2), cost_cutting     DECIMAL(9, 2), cost_rm_without_nds DECIMAL(9, 2), fabricator_id INT)
	DECLARE @spcv_need_chestny_znak TABLE(spcv_id INT, spcvts_id INT, ean VARCHAR(14), cnt SMALLINT, order_num INT, fabricator_id int )
	DECLARE @order_chestny_znak_out TABLE (ocz_id INT, order_num INT, fabricator_id int )
	DECLARE @count_spcv_cz INT
	DECLARE @season_local_id INT
	DECLARE @pa_tab_for_wb TABLE(pa_id INT, fabricator_id INT)
	
	DECLARE @sketch_tab TABLE (sketch_id INT, cutting_cnt SMALLINT, amount_rm DECIMAL(9, 2), amount_cutting     DECIMAL(9, 2))
	DECLARE @proc_id INT	
	EXECUTE @proc_id = History.ProcId_GetByName @procid = @@PROCID
	
	DECLARE @office_id INT
	DECLARE @doc_dt DATETIME2(0) 
	
	INSERT INTO @spcv_tab
		(
			spcv_id,
			pan_id,
			cost_rm,
			cost_work,
			cost_fix,
			cost_add,
			price_ru,
			cost_cutting,
			cost_rm_without_nds,
			fabricator_id
		)
	SELECT	ml.value('@spcv', 'int'),
			spcv.pan_id,
			ml.value('@rm', 'decimal(9,2)'),
			ml.value('@work', 'decimal(9,2)'),
			ml.value('@fix', 'decimal(9,2)'),
			ml.value('@add', 'decimal(9,2)'),
			ml.value('@price', 'decimal(9,2)'),
			ml.value('@cut', 'decimal(9,2)'),
			ml.value('@rm_no_nds', 'decimal(9,2)'),
			spcv.sew_fabricator_id as fabricator_id
	FROM	@spcv_xml.nodes('root/det')x(ml)   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = ml.value('@spcv',
			'int')
	
	INSERT INTO @sketch_tab
		(
			sketch_id,
			cutting_cnt,
			amount_rm,
			amount_cutting
		)
	SELECT	ml.value('@sketch', 'int'),
			ml.value('@cnt', 'int'),
			ml.value('@rm', 'decimal(9,2)'),
			ml.value('@cut', 'decimal(9,2)')
	FROM	@sketch_xml.nodes('root/det')x(ml)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) +
	      	                        ' не закрыта. Записывать себистоимость нельзя'
	      	                   WHEN ISNULL(oaa.covering_issue_amount, 0) = 0 AND ISNULL(oa_d.season_local_id, 0) != 7 THEN 
	      	                        'По этой выдаче стоимость выданных материалов = 0. Записывать себистоимость нельзя'
	      	                   WHEN oaa.cnt_no_return != 0 THEN 'В выдаче есть шк, которые не вернули на склад. Записывать себистоимость нельзя'
	      	                   WHEN oaa.no_close_price != 0 THEN 'В выдаче есть шк, с незакрытым поступлением. Записывать себистоимость нельзя'
	      	                   WHEN oaa.zero_price != 0 THEN 'В выдаче есть шк, с нулевой стоимостью. Записывать себистоимость нельзя'
	      	                   WHEN oaac.actual_count = 0 THEN 'По этой выдаче не внесено количество кроя. Отправлять на себистоимость нельзя'
	      	                   WHEN oast.amount_rm < oaa.covering_issue_amount - 0.09 OR  oast.amount_rm > oaa.covering_issue_amount + 0.09  THEN 'Не совпадает стоимость выданных шк ' + CAST(oaa.covering_issue_amount AS VARCHAR(10)) 
	      	                        + ' и сумма распределения ' + CAST(oast.amount_rm AS VARCHAR(10))
	      	                   ELSE NULL
	      	              END,
	      	 @office_id = c.office_id,
	      	 @doc_dt	= c.create_dt,
	      	 @season_local_id = ISNULL(oa_d.season_local_id, 0)
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id   
			OUTER APPLY (
			      	SELECT	CAST(ROUND(SUM(sma.amount * (cis.stor_unit_residues_qty - ISNULL(cis.return_stor_unit_residues_qty, 0)) / sma.stor_unit_residues_qty) ,2,1) AS DECIMAL(9,2))
			      	      	covering_issue_amount,
			      			SUM(CASE WHEN cis.return_dt IS NULL THEN 1 ELSE 0 END) cnt_no_return,
			      			SUM(CASE WHEN sma.final_dt IS NULL THEN 1 ELSE 0 END) no_close_price,
			      			SUM(CASE WHEN sma.amount = 0 THEN 1 ELSE 0 END) zero_price
			      	FROM	Planing.CoveringIssueSHKRm cis   
			      			INNER JOIN	Warehouse.SHKRawMaterialAmount sma
			      				ON	sma.shkrm_id = cis.shkrm_id
			      	WHERE	cis.covering_id = @covering_id
			      			AND ISNULL(cis.return_qty, 0) != cis.qty
			      )oaa
			OUTER APPLY (
	      			SELECT	SUM(ca.actual_count) actual_count
	      			FROM	Manufactory.Cutting cut   
	      					INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	      						ON	spcvt.spcvts_id = cut.spcvts_id   
	      					INNER JOIN	Planing.SketchPlanColorVariant spcv
	      						ON	spcv.spcv_id = spcvt.spcv_id   
	      					INNER JOIN	Planing.CoveringDetail cd
	      						ON	cd.spcv_id = spcv.spcv_id   
	      					INNER JOIN	Manufactory.CuttingActual ca
	      						ON	ca.cutting_id = cut.cutting_id
	      			WHERE	cd.covering_id = c.covering_id
				  ) oaac
			OUTER APPLY (
	      			SELECT	SUM(skt.amount_rm)     amount_rm
	      			FROM	@sketch_tab            skt
				  ) oast
			OUTER APPLY (
			      	SELECT	MAX(sp.season_local_id) season_local_id
			      	    	 FROM	Planing.CoveringDetail cd   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      	    	 			ON	spcv.spcv_id = cd.spcv_id 
			      	    	 		INNER JOIN Planing.SketchPlan sp
			      	    	 			ON sp.sp_id = spcv.sp_id			      	    	 		
			      	    	 WHERE	cd.covering_id = c.covering_id
			      	    	 		AND	cd.is_deleted = 0
			      ) oa_d
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN spcv.spcv_id IS NULL THEN 'Цветоварианта с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) + ' не существует'
	      	                   WHEN spcv.spcv_id IS NOT NULL AND st.pan_id IS NULL THEN 'Цветовариант с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) +
	      	                        ' не связан с артикулом сайта.'
	      	                   --WHEN spcv.spcv_id IS NOT NULL AND st.pan_id IS NOT NULL AND pan.nm_id IS NULL THEN 'Цветовариант с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) 
	      	                   --     +
	      	                   --     ' не не записан на сайт.'
	      	                   WHEN cd.cd_id IS NULL THEN 'Цветовариант с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) + ' не находится в текущей выдаче № ' + CAST(@covering_id AS VARCHAR(10))
	      	                   WHEN ISNULL(st.cost_rm, 0) = 0 THEN 'У цветоварианта с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) +
	      	                        ' .Не указана себистоимость по материалам'
	      	                   WHEN ISNULL(st.cost_work, 0) = 0 THEN 'У цветоварианта с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) +
	      	                        ' .Не указана себистоимость по работам'
	      	                   WHEN ISNULL(st.cost_fix, 0) = 0 THEN 'У цветоварианта с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) +
	      	                        ' .Не указана себистоимость по постоянным затратам'
	      	                   WHEN ISNULL(st.price_ru, 0) = 0 THEN 'У цветоварианта с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) + ' .Не указана розница'
	      	                   ELSE NULL
	      	              END
	FROM	@spcv_tab st   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = st.spcv_id   
			LEFT JOIN Planing.SketchPlan sp
				ON sp.sp_id = spcv.sp_id
			LEFT JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			LEFT JOIN	Planing.CoveringDetail cd
				ON	cd.spcv_id = spcv.spcv_id
				AND	cd.covering_id = @covering_id
	WHERE	ISNULL(sp.season_local_id, 0) != 7 
	 		AND( spcv.spcv_id IS NULL
			OR	st.pan_id IS NULL
			OR	pan.nm_id IS NULL
			OR	cd.cd_id IS NULL
			OR	ISNULL(st.cost_rm, 0) = 0
			OR	ISNULL(st.cost_work, 0) = 0
			OR	ISNULL(st.cost_fix, 0) = 0
			OR	ISNULL(st.price_ru, 0) = 0)
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END

	INSERT INTO Synchro.ProductsForEAN
		(
			pants_id,
			fabricator_id
		)
	SELECT	pants.pants_id, f.fabricator_id
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = st.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = spcv.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id
				AND	pants.ts_id = spcvt.ts_id 
			LEFT JOIN   Settings.Fabricators f 
					ON f.fabricator_id = spcv.sew_fabricator_id  
			LEFT JOIN	Synchro.ProductsForEAN e
				ON	e.pants_id = pants.pants_id
				AND e.fabricator_id = f.fabricator_id	
	WHERE	e.pants_id IS NULL
			AND f.activ = 1; 


	SELECT	@error_text = CASE 
	      	                   WHEN st.spcv_id IS NULL THEN 'Цветовариант в выдаче, с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) + ' не имеет себестомости'
	      	                   WHEN skt.sketch_id IS NULL THEN 'Для эскиза с кодом ' + CAST(skt.sketch_id AS VARCHAR(10)) + ' нет данных '
	      	                   WHEN pan.pan_id IS NULL THEN 'Цветовариант в выдаче, с кодом ' + CAST(st.spcv_id AS VARCHAR(10)) + ' не связан с артикулом сайта'
	      	                   WHEN pan.pan_id IS NOT NULL AND tnvds.ts_id IS NULL THEN 'На артикул ' + pa.sa + pan.sa + ' не удалось определить код ТНВД, обратитесь к руководителю'
	      	                   ELSE NULL
	      	              END
	FROM	Planing.CoveringDetail cd   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = cd.spcv_id   
			INNER JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			LEFT JOIN	@spcv_tab st
				ON	st.spcv_id = cd.spcv_id   
			LEFT JOIN	@sketch_tab skt
				ON	skt.sketch_id = sp.sketch_id
			LEFT JOIN Products.ProdArticleNomenclature pan
				ON pan.pan_id = spcv.pan_id
			LEFT JOIN Products.ProdArticle pa
				ON pa.pa_id = pan.pa_id
			LEFT JOIN Products.Sketch s
				ON s.sketch_id = sp.sketch_id
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
	WHERE	cd.covering_id = @covering_id
			AND	(st.spcv_id IS NULL OR skt.sketch_id IS NULL OR pan.pan_id IS NULL OR tnvds.ts_id IS NULL) 
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	SELECT	@error_text = CASE 
	      	                   WHEN s.sketch_id IS NULL THEN 'Эскиза с кодом ' + CAST(st.sketch_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN s.sketch_id IS NOT NULL AND oa.sketch_id IS NULL THEN 'Эскиз с кодом ' + CAST(st.sketch_id AS VARCHAR(10)) + ' нет в выдаче'
	      	                   WHEN ISNULL(st.cutting_cnt, 0) = 0 AND @season_local_id != 7 THEN 'У эскиза с кодом ' + CAST(st.sketch_id AS VARCHAR(10)) + ' не указано количество кроя'
	      	                   WHEN ISNULL(st.amount_rm, 0) = 0 AND @season_local_id != 7 THEN 'У эскиза с кодом ' + CAST(st.sketch_id AS VARCHAR(10)) +
	      	                        ' не указана стоимость материалов'
	      	                   ELSE NULL
	      	              END
	FROM	@sketch_tab st   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = st.sketch_id   
			OUTER APPLY (
			      	SELECT	TOP(1) sp.sketch_id
			      	FROM	Planing.CoveringDetail cd   
			      			INNER JOIN	Planing.SketchPlanColorVariant spcv
			      				ON	spcv.spcv_id = cd.spcv_id   
			      			INNER JOIN	Planing.SketchPlan sp
			      				ON	sp.sketch_id = s.sketch_id
			      	WHERE	sp.sketch_id = st.sketch_id
			      )oa
	WHERE	s.sketch_id IS NULL
			OR	oa.sketch_id IS NULL
			OR	ISNULL(st.cutting_cnt, 0) = 0
			OR	ISNULL(st.amount_rm, 0) = 0
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	INSERT INTO @spcv_need_chestny_znak
		(
			spcv_id,
			spcvts_id, 
			ean,
			cnt,
			fabricator_id
		)
	SELECT	st.spcv_id,
			spcvt.spcvts_id,
			e.ean,
			ISNULL(oa_ac.actual_count, 0) - ISNULL(oa_cwo.write_off, 0) cnt,
			st.fabricator_id
	FROM	@spcv_tab st   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = st.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcv_id = spcv.spcv_id 
			INNER JOIN Products.ProdArticleNomenclature pan
				ON pan.pan_id = spcv.pan_id 
			INNER JOIN Products.ProdArticleNomenclatureTechSize pants
				ON pants.pan_id = pan.pan_id AND pants.ts_id = spcvt.ts_id
			LEFT JOIN Manufactory.EANCode e
				ON e.pants_id = pants.pants_id 
				AND e.fabricator_id = st.fabricator_id
			OUTER APPLY (
			      	SELECT	ISNULL(SUM(ca.actual_count), 0) actual_count
			      	FROM	Manufactory.Cutting cut   
			      			INNER JOIN	Manufactory.CuttingActual ca
			      				ON	ca.cutting_id = cut.cutting_id
			      	WHERE	cut.spcvts_id = spcvt.spcvts_id
							and cut.fabricator_id = spcv.sew_fabricator_id
			      ) oa_ac 
			OUTER APPLY (
	      			SELECT	SUM(1) write_off
	      			FROM	Manufactory.Cutting cut   
	      					INNER JOIN	Manufactory.ProductUnicCode puc
	      						ON	puc.cutting_id = cut.cutting_id
	      			WHERE	cut.spcvts_id = spcvt.spcvts_id
	      					AND	puc.operation_id IN (12, 3)
				  ) oa_cwo
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	Products.ProdArticle pa  
	     				INNER JOIN	Products.Sketch s
	     					ON	s.sketch_id = pa.sketch_id   
	     				OUTER APPLY (
	     				      	SELECT	TOP(1) c.consist_type_id
	     				      	FROM	Products.ProdArticleConsist pac   
	     				      			INNER JOIN	Products.Consist c
	     				      				ON	c.consist_id = pac.consist_id
	     				      	WHERE	pac.pa_id = pa.pa_id
	     				      	ORDER BY
	     				      		pac.percnt DESC
	     				      ) oa_ct
	     				INNER JOIN	Products.TNVED_Settigs tnvds
	     					ON	tnvds.subject_id = s.subject_id
	     					AND	tnvds.ct_id = s.ct_id
	     					AND	tnvds.consist_type_id = oa_ct.consist_type_id   
	     				INNER JOIN	Products.TNVDFromChestnyZnak tcz
	     					ON	tnvds.tnved_id = tcz.tnved_id
	     		WHERE	pa.pa_id = pan.pa_id 
	)
	AND ISNULL(oa_ac.actual_count, 0) - ISNULL(oa_cwo.write_off, 0) > 0
	
	IF EXISTS(SELECT 1 FROM @spcv_need_chestny_znak WHERE ean IS NULL)
	BEGIN
		RAISERROR('Не подгружены коды ЕАН, обратитесь к разработчику',16,1)
		RETURN
	END
	
	IF EXISTS(SELECT 1 FROM @spcv_need_chestny_znak WHERE fabricator_id IS NULL)
	BEGIN
		RAISERROR('Есть товары без производителя с маркировкой ЧЗ, обратитесь к разработчику',16,1)
		RETURN
	END
	
	IF (SELECT COUNT(DISTINCT fabricator_id) FROM @spcv_need_chestny_znak) > 1
	BEGIN
		RAISERROR('Более одно производителя в выдаче, для товаров с маркировкой ЧЗ',16,1)
		RETURN
	END
	
	SELECT @count_spcv_cz = COUNT(1)
	FROM @spcv_need_chestny_znak sncz
	
	;WITH cte AS
 		(
 			SELECT	NTILE((@count_spcv_cz -1) / 10 + 1) OVER(ORDER BY sncz.spcvts_id) order_num, sncz.spcvts_id
 			FROM	@spcv_need_chestny_znak sncz
 		)
	 UPDATE	sncz
	 SET 	sncz.order_num = c.order_num
	 FROM	@spcv_need_chestny_znak sncz
 			INNER JOIN	cte c
 				ON	sncz.spcvts_id = c.spcvts_id	
	
	
	INSERT INTO @pa_tab_for_wb
		(
			pa_id,
			fabricator_id
		)
	SELECT	pa.pa_id,
			t.fabricator_id
	FROM	Products.ProdArticle pa
		outer APPLY ( select  top 1 st.fabricator_id from Products.ProdArticleNomenclature pan   
	     				INNER JOIN	@spcv_tab  st
	     					ON	st.pan_id = pan.pan_id
	     		WHERE	pan.pa_id = pa.pa_id
	     			) as t
	WHERE	EXISTS (
	     		SELECT	1
	     		FROM	Products.ProdArticleNomenclature pan   
	     				INNER JOIN	@spcv_tab st
	     					ON	st.pan_id = pan.pan_id
	     		WHERE	pan.pa_id = pa.pa_id
	     				AND	pan.nm_id IS NULL
	     	)

	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Planing.Covering
		SET 	cost_dt              = @dt,
				cost_employee_id     = @employee_id
		WHERE	covering_id          = @covering_id
		
		;WITH cte_target AS (
			SELECT	ccd.ccd_id,
					ccd.covering_id,
					ccd.sketch_id,
					ccd.cutting_cnt,
					ccd.amount_rm,
					ccd.dt,
					ccd.employee_id,
					ccd.amount_cutting										
			FROM	Planing.CoveringCostDetail ccd
			WHERE	ccd.covering_id = @covering_id
		)
		MERGE cte_target t
		USING (
		      	SELECT	skt.sketch_id,
		      			skt.cutting_cnt,
		      			skt.amount_rm,
		      			skt.amount_cutting
		      	FROM	@sketch_tab skt
		      ) s
				ON t.sketch_id = s.sketch_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	cutting_cnt     = s.cutting_cnt,
		     		amount_rm       = s.amount_rm,
		     		dt              = @dt,
		     		employee_id     = @employee_id,
		     		amount_cutting	= s.amount_cutting
		WHEN NOT MATCHED BY TARGET THEN 
		     INSERT
		     	(
		     		covering_id,
		     		sketch_id,
		     		cutting_cnt,
		     		amount_rm,
		     		dt,
		     		employee_id,
		     		amount_cutting
		     	)
		     VALUES
		     	(
		     		@covering_id,
		     		s.sketch_id,
		     		s.cutting_cnt,
		     		s.amount_rm,
		     		@dt,
		     		@employee_id,
		     		s.amount_cutting
		     	)
		WHEN NOT MATCHED BY SOURCE THEN 
		     DELETE	;
		
		WITH cte_target AS (
			SELECT	spcvc.spcv_id,
					spcvc.pan_id,
					spcvc.dt,
					spcvc.employee_id,
					spcvc.cost_rm,
					spcvc.cost_work,
					spcvc.cost_fix,
					spcvc.cost_add,
					spcvc.price_ru,
					spcvc.cost_cutting,
					spcvc.cost_rm_without_nds,
					spcvc.create_dt
			FROM	Planing.SketchPlanColorVariantCost spcvc
			WHERE	EXISTS(
			     		SELECT	1
			     		FROM	@spcv_tab st
			     		WHERE	st.spcv_id = spcvc.spcv_id
			     	)
		)
		MERGE cte_target t
		USING (
		      	SELECT	st.spcv_id,
		      			st.pan_id,
		      			st.cost_rm,
		      			st.cost_work,
		      			st.cost_fix,
		      			st.cost_add,
		      			st.price_ru,
		      			st.cost_cutting,
		      			st.cost_rm_without_nds
		      	FROM	@spcv_tab st
		      ) s
				ON s.spcv_id = t.spcv_id
		WHEN MATCHED THEN 
		     UPDATE	
		     SET 	pan_id          = s.pan_id,
		     		dt              = @dt,
		     		employee_id     = @employee_id,
		     		cost_rm         = s.cost_rm,
		     		cost_work       = s.cost_work,
		     		cost_fix        = s.cost_fix,
		     		cost_add        = s.cost_add,
		     		price_ru        = s.price_ru,
		     		cost_cutting	= s.cost_cutting,
		     		cost_rm_without_nds = s.cost_rm_without_nds
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		spcv_id,
		     		pan_id,
		     		dt,
		     		employee_id,
		     		cost_rm,
		     		cost_work,
		     		cost_fix,
		     		cost_add,
		     		price_ru,
		     		cost_cutting,
		     		cost_rm_without_nds,
		     		create_dt
		     	)
		     VALUES
		     	(
		     		s.spcv_id,
		     		s.pan_id,
		     		@dt,
		     		@employee_id,
		     		s.cost_rm,
		     		s.cost_work,
		     		s.cost_fix,
		     		s.cost_add,
		     		s.price_ru,
		     		s.cost_cutting,
		     		s.cost_rm_without_nds,
		     		@dt
		     	) 
		     OUTPUT	INSERTED.spcv_id,
		     		INSERTED.pan_id,
		     		INSERTED.dt,
		     		INSERTED.employee_id,
		     		INSERTED.cost_rm,
		     		INSERTED.cost_work,
		     		INSERTED.cost_fix,
		     		INSERTED.cost_add,
		     		INSERTED.price_ru,
		     		@proc_id,
		     		INSERTED.cost_cutting,
		     		INSERTED.cost_rm_without_nds
		     INTO	History.SketchPlanColorVariantCost (
		     		spcv_id,
		     		pan_id,
		     		dt,
		     		employee_id,
		     		cost_rm,
		     		cost_work,
		     		cost_fix,
		     		cost_add,
		     		price_ru,
		     		proc_id,
		     		cost_cutting,
		     		cost_rm_without_nds
		     	);
		
		UPDATE	pan
		SET 	whprice = st.cost_rm + st.cost_work + st.cost_fix + st.cost_add + st.cost_cutting,
				price_ru = st.price_ru
				OUTPUT	INSERTED.pan_id,
						INSERTED.employee_id,
						INSERTED.dt,
						INSERTED.whprice,
						INSERTED.price_ru
				INTO	History.ProdArticleNomenclaturePrice (
						pan_id,
						employee_id,
						dt,
						whprice,
						price_ru
					)
		FROM	Products.ProdArticleNomenclature pan
				INNER JOIN	@spcv_tab st
					ON	st.pan_id = pan.pan_id 
					
		;
		WITH cte_target AS
			(
				SELECT	pafw.pa_id,
						pafw.dt,
						pafw.send_dt,
						pafw.imt_uid,
						pafw.is_error,
						pafw.load_nm_dt,
						pafw.fabricator_id
				FROM	Wildberries.ProdArticleForWB pafw   
						INNER JOIN	@pa_tab_for_wb ptfw
							ON	ptfw.pa_id = pafw.pa_id
			) 
		MERGE cte_target t
		USING @pa_tab_for_wb s
				ON s.pa_id = t.pa_id
		WHEN MATCHED AND (t.send_dt IS NOT NULL OR t.load_nm_dt IS NOT NULL) THEN 
		     UPDATE	
		     SET 	send_dt        = NULL,
		     		load_nm_dt     = NULL,
		     		dt             = @dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pa_id,
		     		dt,
					fabricator_id
					
		     	)
		     VALUES
		     	(
		     		s.pa_id,
		     		@dt,
					s.fabricator_id
		     	);			
		
		;
		WITH cte_target AS
			(
				SELECT	panfo.pan_id,
						panfo.dt,
						panfo.send_dt,
						panfo.is_error,
						panfo.load_ozon_id_dt,
						panfo.is_deleted
				FROM	Ozon.ProdArticleNomenclatureForOZON panfo   
						INNER JOIN	@spcv_tab ptfw
							ON	ptfw.pan_id = panfo.pan_id
			) 
		MERGE cte_target t
		USING (SELECT distinct st.pan_id FROM @spcv_tab st) s
				ON s.pan_id = t.pan_id
		WHEN MATCHED AND (t.send_dt IS NOT NULL OR t.load_ozon_id_dt IS NOT NULL OR t.is_deleted = 1) THEN 
		     UPDATE	
		     SET 	send_dt             = NULL,
		     		load_ozon_id_dt     = NULL,
		     		is_deleted          = 0,
		     		dt                  = @dt
		WHEN NOT MATCHED THEN 
		     INSERT
		     	(
		     		pan_id,
		     		dt,
		     		is_deleted
		     		
		     	)
		     VALUES
		     	(
		     		s.pan_id,
		     		@dt,
		     		0
		     	);
				
	
			INSERT INTO Synchro.Upload_Covering_BuhVas
			(
				covering_id,
				dt
			)
			SELECT	@covering_id,
					@dt
			WHERE NOT EXISTS (SELECT NULL FROM Synchro.Upload_Covering_BuhVas t WHERE t.covering_id = @covering_id)

		
		IF EXISTS(
		   	SELECT	1
		   	FROM	@spcv_need_chestny_znak sncz
		) AND NOT EXISTS (
		         		SELECT	1
		         		FROM	Manufactory.OrderChestnyZnak ocz
		         		WHERE	ocz.covering_id = @covering_id
		         	)
		BEGIN
		    ;
		    MERGE Manufactory.OrderChestnyZnak t
		    USING (
		          	SELECT	sncz.order_num, sncz.fabricator_id
		          	FROM	@spcv_need_chestny_znak sncz
		          	GROUP BY
		          		sncz.order_num, sncz.fabricator_id
		          ) s
				ON t.ocz_id = NULL
		    WHEN NOT MATCHED THEN
		    INSERT
		    	(
		    		covering_id,
		    		create_dt,
		    		dt,
		    		employee_id,
		    		is_deleted,
		    		fabricator_id
		    	)
		    VALUES
		    	(
		    		@covering_id,
		    		@dt,
		    		@dt,
		    		@employee_id,
		    		0,
		    		s.fabricator_id
		    	)
		    OUTPUT	INSERTED.ocz_id,
		    		s.order_num,
		    		s.fabricator_id
		    INTO	@order_chestny_znak_out (
		    		ocz_id,
		    		order_num,
		    		fabricator_id
		    	);

		   INSERT INTO Manufactory.OrderChestnyZnakDetail
		        	(
		        		ocz_id,
		        		spcvts_id,
		        		ean,
		        		cnt
		        	)
		   SELECT	oczo.ocz_id,
		        		spcvcz.spcvts_id,
		        		spcvcz.ean,
		        		spcvcz.cnt
		        FROM	@spcv_need_chestny_znak spcvcz   
		        		INNER JOIN	@order_chestny_znak_out oczo
		        			ON	oczo.order_num = spcvcz.order_num
		        			AND oczo.fabricator_id = spcvcz.fabricator_id
		        		

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
		--WITH LOG;
	END CATCH
	
