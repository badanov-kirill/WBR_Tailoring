CREATE PROCEDURE [Manufactory].[RepairPlan_Find]
	@sa VARCHAR(36) = NULL,
	@art_name VARCHAR(50) = NULL,
	@product_unic_code INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
	IF @sa IS NULL
	   AND @art_name IS NULL
	   AND ISNULL(@product_unic_code, 0) = 0
	BEGIN
	    RAISERROR('Не указан ни один параметр отбора', 16, 1)
	    RETURN
	END
	
	SELECT	TOP(50) pan.nm_id,
			pa.sa + pan.sa sa,
			ISNULL(s.imt_name, sj.subject_name_sf) imt_name,
			b.brand_name,
			ISNULL(pan.cutting_degree_difficulty, 1) cutting_degree_difficulty,
			pan.pan_id,
			an.art_name,
			s.pt_id,
			pt.pt_name,
			s.sa_local,
			pa.sketch_id,
			pants.pants_id,
			ts.ts_name,
			os.organization_name,
			os.label_address,
			os.office_id
	FROM	Products.ProdArticle pa   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pa_id = pa.pa_id   
			INNER JOIN	Products.Sketch s
				ON	s.sketch_id = pa.sketch_id   
			INNER JOIN	Products.[Subject] sj
				ON	sj.subject_id = s.subject_id   
			INNER JOIN	Products.Brand b
				ON	b.brand_id = pa.brand_id   
			INNER JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProductType pt
				ON	pt.pt_id = s.pt_id   
			INNER JOIN	Products.ProdArticleNomenclatureTechSize pants
				ON	pants.pan_id = pan.pan_id   
			INNER JOIN	Products.TechSize ts
				ON	ts.ts_id = pants.ts_id   
			LEFT JOIN	Settings.OfficeSetting os
				ON	os.is_main_wh = 1
	WHERE	(@sa IS NULL OR pa.sa + pan.sa LIKE @sa + '%')
			AND	(@art_name IS NULL OR an.art_name LIKE @art_name + '%')
			AND	pan.nm_id IS NOT NULL
			AND	(
			   		@product_unic_code IS NULL
			   		OR EXISTS(
			   		   	SELECT	1
			   		   	FROM	Manufactory.ProductUnicCode puc
			   		   	WHERE	puc.product_unic_code = @product_unic_code
			   		   			AND	puc.pants_id = pants.pants_id
			   		   )
			   	)