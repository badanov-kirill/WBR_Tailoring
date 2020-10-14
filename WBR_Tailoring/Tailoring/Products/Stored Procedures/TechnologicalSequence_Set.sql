CREATE PROCEDURE [Products].[TechnologicalSequence_Set]
	@stj_id INT,
	@data_xml XML,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	DECLARE @error_text VARCHAR(MAX)
	DECLARE @sketch_id INT
	
	
	
	SELECT	@error_text = CASE 
	      	                   WHEN stj.stj_id IS NULL THEN 'Задания на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) +
	      	                        ' не существует.'
	      	                   WHEN stj.begin_dt IS NULL THEN 'Задание на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) +
	      	                        ' не взято в работу.'
	      	                   WHEN stj.end_dt IS NOT NULL THEN 'Задание на написание техпоследовательности с кодом ' + CAST(v.stj_id AS VARCHAR(10)) +
	      	                        ' уже выполнено.'
	      	                   ELSE NULL
	      	              END,
			@sketch_id = stj.sketch_id
	FROM	(VALUES(@stj_id))v(stj_id)   
			LEFT JOIN	Products.SketchTechnologyJob stj
				ON	stj.stj_id = v.stj_id
	
	IF @error_text IS NOT NULL
	BEGIN
	    RAISERROR('%s', 16, 1, @error_text)
	    RETURN
	END
	
	EXEC Products.TechnologicalSequence_SetBySketch @sketch_id = @sketch_id,
	     @data_xml = @data_xml,
	     @employee_id = @employee_id
	
