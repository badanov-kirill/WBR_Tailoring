CREATE PROCEDURE [Warehouse].[SHKRawMaterialReserv_GetByShk]
	@shkrm_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(smr.dt AS DATETIME)         dt,
			smr.quantity,
			o.symbol                         okei_symbol,
			smr.employee_id,
			c.completing_name,
			spcvc.completing_number,
			ISNULL(pa.sa + pan.sa, s.sa)     sa,
			an.art_name,
			smr.spcvc_id,
			smr.shkrm_id,
			spcv.spcv_name,
			es.employee_name
	FROM	Warehouse.SHKRawMaterialReserv smr   
			LEFT JOIN	Qualifiers.OKEI o
				ON	o.okei_id = smr.okei_id   
			LEFT JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcvc_id = smr.spcvc_id   
			LEFT JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			LEFT JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = spcvc.spcv_id   
			LEFT JOIN	Planing.SketchPlan sp
				ON	sp.sp_id = spcv.sp_id   
			LEFT JOIN	Products.Sketch s
				ON	s.sketch_id = sp.sketch_id   
			LEFT JOIN	Products.ArtName an
				ON	an.art_name_id = s.art_name_id   
			LEFT JOIN	Products.ProdArticleNomenclature pan   
			INNER JOIN	Products.ProdArticle pa
				ON	pa.pa_id = pan.pa_id
				ON	pan.pan_id = spcv.pan_id
			LEFT JOIN Settings.EmployeeSetting es 
				ON es.employee_id = smr.employee_id
	WHERE	smr.shkrm_id = @shkrm_id
	ORDER BY smr.quantity DESC