CREATE PROCEDURE [Products].[LabelInfo_Get]
	@pants_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @lining_ao_id INT = 4
	
	DECLARE @t TABLE(pants_id INT, ts_name VARCHAR(15), sa VARCHAR(72), brand_name VARCHAR(50), pan_id INT, pa_id INT, nm_id INT)
	
	INSERT INTO @t
	  (
	    pants_id,
	    ts_name,
	    sa,
	    brand_name,
	    pan_id,
	    pa_id,
	    nm_id
	  )
	SELECT	pants.pants_id,
			ts.ts_name,
			pa.sa + pan.sa                 sa,
			b.brand_name,
			pan.pan_id,
			pa.pa_id,
			pan.nm_id
	FROM	Products.ProdArticleNomenclatureTechSize pants   
			INNER JOIN	Products.TechSize AS ts
				ON	ts.ts_id = pants.ts_id   
			INNER JOIN	Products.ProdArticleNomenclature pan
				ON	pan.pan_id = pants.pan_id   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id   
			INNER JOIN	Products.Brand  AS b
				ON	b.brand_id = pa.brand_id
	WHERE	pants.pants_id = @pants_id
	
	SELECT	t.pants_id,
			t.ts_name,
			t.sa,
			t.brand_name,
			t.pan_id,
			t.pa_id,
			t.nm_id
	FROM	@t t
	
	SELECT	c.consist_name,
			c.consist_name_eng,
			pac.percnt
	FROM	@t t   
			INNER JOIN	Products.ProdArticleConsist pac
				ON	pac.pa_id = t.pa_id   
			INNER JOIN	Products.Consist AS c
				ON	c.consist_id = pac.consist_id
	
	SELECT	ao.ao_name,
			ao.ao_name_eng,
			CAST(paao.ao_value AS INT) percnt
	FROM	@t t   
			INNER JOIN	Products.ProdArticleAddedOption paao
				ON	paao.pa_id = t.pa_id   
			INNER JOIN	Products.AddedOption AS ao
				ON	ao.ao_id = paao.ao_id
	WHERE	ao.ao_id_parent = @lining_ao_id
			AND ao.ao_id != 26
	SELECT	ctao.img_name
	FROM	@t t   
			INNER JOIN	Products.ProdArticleAddedOption paao
				ON	paao.pa_id = t.pa_id   
			INNER JOIN	Products.AddedOption AS ao
				ON	ao.ao_id = paao.ao_id   
			INNER JOIN	Products.CareThingAddedOption ctao
				ON	ctao.ao_id = ao.ao_id
	
	                

