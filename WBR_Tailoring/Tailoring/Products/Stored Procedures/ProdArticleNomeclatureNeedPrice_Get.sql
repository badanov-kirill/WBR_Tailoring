CREATE PROCEDURE [Products].[ProdArticleNomeclatureNeedPrice_Get]
	@sa VARCHAR(36) = NULL,
	@art_name VARCHAR(100) = NULL,
	@nm_id INT = NULL,
	@need_price BIT = 1
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @need_price = 1
	BEGIN
	    SELECT 	s.sketch_id,
	    		s.create_employee_id,
	    		ISNULL(s.imt_name, sj.subject_name) imt_name,
	    		ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') + pan.sa sa,
	    		pan.whprice,
	    		pan.price_ru,
	    		pan.nm_id,
	    		pan.pan_id,
	    		pa.pa_id
	    FROM	Products.Sketch s   
	    		INNER JOIN	Products.ProdArticle pa
	    			ON	pa.sketch_id = s.sketch_id   
	    		INNER JOIN	Products.ProdArticleNomenclature pan
	    			ON	pan.pa_id = pa.pa_id   
	    		INNER JOIN	Products.ArtName an
	    			ON	an.art_name_id = s.art_name_id   
	    		INNER JOIN	Products.[Subject] sj
	    			ON	sj.subject_id = s.subject_id   
	    		INNER JOIN	Products.ProdArticleNomenclatureNeedPrice pannp 
	    			ON pannp.pan_id = pan.pan_id
	    WHERE	pan.nm_id IS NOT NULL
				AND s.is_deleted = 0
				AND pa.is_deleted = 0
	    		AND	(@sa IS NULL OR pa.sa LIKE @sa + '%' OR s.sa LIKE @sa + '%')
	    		AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
	    		AND (@nm_id IS NULL OR pan.nm_id = @nm_id)
	END
	ELSE
	BEGIN
	    IF @sa IS NULL
	       AND @art_name IS NULL
	       AND @nm_id IS NULL
	    BEGIN
	        RAISERROR('Не указано ни одного условия', 16, 1)
	        RETURN
	    END
	    
	    SELECT	s.sketch_id,
	    		s.create_employee_id,
	    		ISNULL(s.imt_name, sj.subject_name) imt_name,
	    		ISNULL(pa.sa, s.sa + CAST(pa.model_number AS VARCHAR(10)) + '/') + pan.sa sa,
	    		pan.whprice,
	    		pan.price_ru,
	    		pan.nm_id,
	    		pan.pan_id,
	    		pa.pa_id
	    FROM	Products.Sketch s   
	    		INNER JOIN	Products.ProdArticle pa
	    			ON	pa.sketch_id = s.sketch_id   
	    		INNER JOIN	Products.ProdArticleNomenclature pan
	    			ON	pan.pa_id = pa.pa_id   
	    		INNER JOIN	Products.ArtName an
	    			ON	an.art_name_id = s.art_name_id   
	    		INNER JOIN	Products.[Subject] sj
	    			ON	sj.subject_id = s.subject_id
	    WHERE	pan.nm_id IS NOT NULL
				AND s.is_deleted = 0
				AND pa.is_deleted = 0
	    		AND	(@sa IS NULL OR pa.sa LIKE @sa + '%' OR s.sa LIKE @sa + '%')
	    		AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
	    		AND (@nm_id IS NULL OR pan.nm_id = @nm_id)
	END