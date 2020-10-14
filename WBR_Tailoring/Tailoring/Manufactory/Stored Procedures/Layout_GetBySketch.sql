CREATE PROCEDURE [Manufactory].[Layout_GetBySketch]
	@sketch_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	l.layout_id,
			CAST(l.create_dt AS DATETIME) create_dt,
			l.create_employee_id,
			l.frame_width,
			l.layout_length,
			l.effective_percent,
			l.base_consumption consumption,
			c.completing_name,
			l.base_completing_number     completing_number,
			oats.x                       tss,
			oas.x                        added_sketches,
			l.comment
	FROM	Manufactory.Layout l   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = l.base_completing_id   
			OUTER APPLY (
			      	SELECT	ts.ts_name + '(' + CAST(CAST(lt.completing_qty AS INT) AS VARCHAR(10)) + '); '
			      	FROM	Manufactory.LayoutTS lt   
			      			INNER JOIN	Products.TechSize ts
			      				ON	ts.ts_id = lt.ts_id
			      	WHERE	lt.layout_id = l.layout_id
			      	FOR XML	PATH('')
			      ) oats(x)
			OUTER APPLY (
			       	SELECT	sj.subject_name + '|' + an.art_name + '|' + s.sa + ';'
			       	FROM	Manufactory.LayoutAddedSketch las   
			       			INNER JOIN	Products.Sketch s
			       				ON	s.sketch_id = las.sketch_id   
			       			INNER JOIN	Products.ArtName an
			       				ON	an.art_name_id = s.art_name_id   
			       			INNER JOIN	Products.[Subject] sj
			       				ON	sj.subject_id = s.subject_id
			       	WHERE	las.layout_id = l.layout_id
			       	FOR XML	PATH('')
			                     ) oas(x)
	WHERE	l.base_sketch_id = @sketch_id
	AND l.is_deleted = 0