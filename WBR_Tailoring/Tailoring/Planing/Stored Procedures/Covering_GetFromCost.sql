CREATE PROCEDURE [Planing].[Covering_GetFromCost]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.covering_id,
			CAST(c.create_dt AS DATETIME)	 create_dt,
			CAST(c.close_dt AS DATETIME)     close_dt,
			os.office_name,
			oa.x                             art_names,
			oasj.x							 subject_names,
			oa_d.deadline_package_dt
	FROM	Planing.Covering c   
			INNER JOIN	Settings.OfficeSetting os
				ON	os.office_id = c.office_id   
			OUTER APPLY (
			      	SELECT	v.art_name + ' (' + v.sa + '); '
			      	FROM	(SELECT	DISTINCT an.art_name,
			      	    	 		pa.sa
			      	    	 FROM	Planing.CoveringDetail cd   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      	    	 			ON	spcv.spcv_id = cd.spcv_id   
			      	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
			      	    	 			ON	pan.pan_id = spcv.pan_id   
			      	    	 		INNER JOIN	Products.ProdArticle pa
			      	    	 			ON	pa.pa_id = pan.pa_id   
			      	    	 		INNER JOIN	Products.Sketch s
			      	    	 			ON	s.sketch_id = pa.sketch_id   
			      	    	 		INNER JOIN	Products.ArtName an
			      	    	 			ON	an.art_name_id = s.art_name_id
			      	    	 WHERE	cd.covering_id = c.covering_id
			      	    	 		AND	cd.is_deleted = 0)v(art_name,
			      			sa)
			      	FOR XML	PATH('')
			      ) oa(x)
			OUTER APPLY (
			      	SELECT	v.subject_name + '; '
			      	FROM	(SELECT	DISTINCT sj.subject_name
			      	    	 FROM	Planing.CoveringDetail cd   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      	    	 			ON	spcv.spcv_id = cd.spcv_id   
			      	    	 		INNER JOIN	Products.ProdArticleNomenclature pan
			      	    	 			ON	pan.pan_id = spcv.pan_id   
			      	    	 		INNER JOIN	Products.ProdArticle pa
			      	    	 			ON	pa.pa_id = pan.pa_id   
			      	    	 		INNER JOIN	Products.Sketch s
			      	    	 			ON	s.sketch_id = pa.sketch_id  
			      	    	 		INNER JOIN Products.[Subject] sj
			      	    	 			ON sj.subject_id = s.subject_id
			      	    	 WHERE	cd.covering_id = c.covering_id
			      	    	 		AND	cd.is_deleted = 0)v(subject_name)
			      	FOR XML	PATH('')
			      ) oasj(x)
			 OUTER APPLY (
			      	SELECT	CAST(max(spcv.deadline_package_dt) AS DATETIME) deadline_package_dt
			      	    	 FROM	Planing.CoveringDetail cd   
			      	    	 		INNER JOIN	Planing.SketchPlanColorVariant spcv
			      	    	 			ON	spcv.spcv_id = cd.spcv_id 			      	    	 		
			      	    	 WHERE	cd.covering_id = c.covering_id
			      	    	 		AND	cd.is_deleted = 0
			      ) oa_d
	WHERE	c.close_dt IS NOT NULL
			AND	c.cost_dt IS                 NULL