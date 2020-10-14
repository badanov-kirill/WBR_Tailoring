CREATE PROCEDURE [Manufactory].[Completing_GetByTL]
	@tl_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	spcvc.spcvc_id,	
			c.completing_name,
			spcvc.completing_number,
			spcvc.consumption,
			spcvc.frame_width,
			oal.consumption        layout_consumption,
			oafw.x                 layout_frame_width,
			ISNULL(oar.qty, 0)     reserv_qty,
			CASE 
			     WHEN ISNULL(oal.consumption, 0) = 0 AND spcvc.consumption = 0 THEN 0
			     WHEN ISNULL(oal.consumption, 0) = 0 THEN ISNULL(oar.qty, 0) / spcvc.consumption
			     ELSE ISNULL(oar.qty, 0) / oal.consumption
			END complect_qty
	FROM Manufactory.TaskLayout tl   
			INNER JOIN	Planing.SketchPlanColorVariant spcv
				ON	spcv.spcv_id = tl.spcv_id   
			INNER JOIN	Planing.SketchPlanColorVariantCompleting spcvc
				ON	spcvc.spcv_id = spcv.spcv_id   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = spcvc.completing_id   
			OUTER APPLY (
			      	SELECT	AVG(l.base_consumption) consumption
			      	FROM	Manufactory.TaskLayoutDetail tld   
			      			INNER JOIN	Manufactory.Layout l
			      				ON	l.layout_id = tld.layout_id
			      	WHERE	tld.tl_id = tl.tl_id
			      			AND	l.base_completing_id = spcvc.completing_id
			      			AND	l.base_completing_number = spcvc.completing_number
			      ) oal
			OUTER APPLY (
	      			SELECT	DISTINCT CAST(l.frame_width AS VARCHAR(10)) + ';'
	      			FROM	Manufactory.TaskLayoutDetail tld   
	      					INNER JOIN	Manufactory.Layout l
	      						ON	l.layout_id = tld.layout_id
	      			WHERE	tld.tl_id = tl.tl_id
	      					AND	l.base_completing_id = spcvc.completing_id
	      					AND	l.base_completing_number = spcvc.completing_number
	      			FOR XML	PATH('')
				  ) oafw(x)
	      OUTER APPLY (
	              	SELECT	SUM(smr.quantity) qty
	              	FROM	Warehouse.SHKRawMaterialReserv smr
	              	WHERE	smr.spcvc_id = spcvc.spcvc_id
	              )         oar
	WHERE	tl.tl_id = @tl_id