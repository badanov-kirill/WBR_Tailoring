CREATE PROCEDURE [Technology].[DataForRationing]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	ct.ct_name,
			v.ct_id,
			ta.ta_name,
			v.ta_id,
			e.element_name,
			v.element_id,
			eq.equipment_name,
			v.equipment_id,
			oat.t1,
			oat.t2,
			oat.t3,
			oap.p1,
			oap.p2,
			oap.p3
	FROM	(SELECT	tar.ct_id,
	    	 		tar.ta_id,
	    	 		tar.element_id,
	    	 		tar.equipment_id
	    	 FROM	Technology.TechActionRationing tar
	    	UNION 
	    	SELECT	tad.ct_id,
	    	 		tad.ta_id,
	    	 		tad.element_id,
	    	 		tad.equipment_id
	    	 FROM	Technology.TechActionDCCoefficient tad
	    	UNION
	    	SELECT	em.ct_id,
	    			em.ta_id,
	    			tae.element_id,
	    			em.equipment_id
	    	FROM	Technology.EquipmentMapping em   
	    			INNER JOIN	Technology.TechActionElement tae
	    				ON	tae.ta_id = em.ta_id)v   
			INNER JOIN	Material.ClothType ct
				ON	ct.ct_id = v.ct_id   
			INNER JOIN	Technology.TechAction ta
				ON	ta.ta_id = v.ta_id AND ta.is_deleted = 0  
			INNER JOIN	Technology.Element e
				ON	e.element_id = v.element_id AND e.is_deleted = 0
			INNER JOIN	Technology.Equipment eq
				ON	eq.equipment_id = v.equipment_id AND eq.is_deleted = 0
			OUTER APPLY (
			      	SELECT	MAX(CASE WHEN tar.dr_id = 1 THEN tar.rotaiting ELSE NULL END) t1,
			      			MAX(CASE WHEN tar.dr_id = 2 THEN tar.rotaiting ELSE NULL END) t2,
			      			MAX(CASE WHEN tar.dr_id = 3 THEN tar.rotaiting ELSE NULL END) t3
			      	FROM	Technology.TechActionRationing tar
			      	WHERE	tar.ct_id = v.ct_id
			      			AND	tar.ta_id = v.ta_id
			      			AND	tar.element_id = v.element_id
			      			AND	tar.equipment_id = v.equipment_id
			      ) oat
			OUTER APPLY (
	      			SELECT	MAX(CASE WHEN tar.dc_id = 1 THEN tar.dc_coefficient ELSE NULL END) p1,
	      					MAX(CASE WHEN tar.dc_id = 2 THEN tar.dc_coefficient ELSE NULL END) p2,
	      					MAX(CASE WHEN tar.dc_id = 3 THEN tar.dc_coefficient ELSE NULL END) p3
	      			FROM	Technology.TechActionDCCoefficient tar
	      			WHERE	tar.ct_id = v.ct_id
	      					AND	tar.ta_id = v.ta_id
	      					AND	tar.element_id = v.element_id
	      					AND	tar.equipment_id = v.equipment_id
				  ) oap
	
	