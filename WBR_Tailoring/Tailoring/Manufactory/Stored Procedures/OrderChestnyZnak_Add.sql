CREATE PROCEDURE [Manufactory].[OrderChestnyZnak_Add]
	@covering_id INT,
	@spcvts_tab [dbo].[CountList] READONLY,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @spcv_need_chestny_znak TABLE(spcv_id INT, spcvts_id INT, ean VARCHAR(14), cnt SMALLINT, need_cz BIT, fabricator_id int )
	DECLARE @order_chestny_znak_out TABLE (ocz_id INT)
	
	SELECT	@error_text = CASE 
	      	                   WHEN c.covering_id IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не существует.'
	      	                   WHEN c.close_dt IS NULL THEN 'Выдачи с кодом ' + CAST(v.covering_id AS VARCHAR(10)) + ' не закрыта.'
	      	                   ELSE NULL
	      	              END
	FROM	(VALUES(@covering_id))v(covering_id)   
			LEFT JOIN	Planing.Covering c
				ON	c.covering_id = v.covering_id  
	
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END		
	
	IF EXISTS (
	   	SELECT	1
	   	FROM	@spcvts_tab st   
	   			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
	   				ON	spcvt.spcvts_id = st.id   
	   			INNER JOIN	Planing.SketchPlanColorVariant spcv
	   				ON	spcv.spcv_id = spcvt.spcv_id   
	   			LEFT JOIN	Planing.CoveringDetail cd
	   				ON	cd.spcv_id = spcv.spcv_id
	   				AND	cd.covering_id = @covering_id
	   	WHERE	cd.spcv_id IS NULL
	   )
	BEGIN
	    RAISERROR('Размеры не из одной выдачи', 16, 1)
	    RETURN
	END
	
	INSERT INTO @spcv_need_chestny_znak
		(
			spcv_id,
			spcvts_id,
			ean,
			cnt,
			need_cz,
			fabricator_id
		)
	SELECT	spcv.spcv_id,
			spcvt.spcvts_id,
			e.ean,
			st.cnt,
			CASE 
			     WHEN oancz.need_cz = 1 THEN 1
			     ELSE 0
			END         need_cz,
			spcv.sew_fabricator_id
	FROM	@spcvts_tab st   
			INNER JOIN	Planing.SketchPlanColorVariantTS spcvt
				ON	spcvt.spcvts_id = st.id   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvt.spcv_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = spcv.pan_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id
				AND	pants.ts_id = spcvt.ts_id   
			LEFT JOIN	Manufactory.EANCode e
				ON	e.pants_id = pants.pants_id
				AND e.fabricator_id = spcv.sew_fabricator_id				    
			OUTER APPLY (
			      	SELECT	TOP(1) 1 need_cz
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
			      )     oancz
	
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	@spcv_need_chestny_znak
	   	WHERE	ean IS NULL
	   )
	BEGIN
	    RAISERROR('Не подгружены коды ЕАН, попробуйте позже или обратитесь к разработчику', 16, 1)
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
		
	
	IF EXISTS(
	   	SELECT	1
	   	FROM	@spcv_need_chestny_znak
	   	WHERE	need_cz = 0
	   			AND	cnt > 0
	   )
	BEGIN
	    RAISERROR('Заказ кодов на позиции, которые не требуют маркировки', 16, 1)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		INSERT INTO Manufactory.OrderChestnyZnak
			(
				covering_id,
				create_dt,
				dt,
				employee_id,
				is_deleted,
				fabricator_id
			)OUTPUT	INSERTED.ocz_id
			 INTO	@order_chestny_znak_out (
			 		ocz_id
			 	)
		select
				@covering_id,
				@dt,
				@dt,
				@employee_id,
				0,
				sncz.fabricator_id
		FROM @spcv_need_chestny_znak AS sncz
		WHERE sncz.need_cz = 1 AND sncz.cnt > 0
		GROUP BY sncz.fabricator_id
		
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
				CROSS JOIN	@order_chestny_znak_out oczo
		WHERE spcvcz.need_cz = 1 AND spcvcz.cnt > 0
		
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
	
