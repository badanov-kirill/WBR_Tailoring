CREATE PROCEDURE [Products].[SketchCard_Add_1c]
	@employee_id INT,
	@st_id INT,
	@kind_id INT,
	@subject_id INT,
	@descr VARCHAR(1000),
	@pic_count TINYINT,
	@tech_design BIT,
	@status_comment VARCHAR(250) = NULL,
	@qp_id TINYINT,
	@brand_id INT,
	@season_id INT,
	@pattern_name VARCHAR(15) = NULL,
	@model_year SMALLINT,
	@art_name VARCHAR(100),
	@constructor_employee_id INT = NULL,
	@ct_id INT,
	@xml_data XML,
	@direction_id INT = NULL,
	@imt_name VARCHAR(100) = NULL,
	@season_local_id INT = NULL,
	@plan_site_dt DATE = NULL,
	@is_china_sample BIT = 0
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @content_list Products.ContentList 
	DECLARE @tech_size_list dbo.List 
	
	INSERT INTO @tech_size_list
	  (
	    id
	  )
	SELECT	ml.value('@id', 'smallint')
	FROM	@xml_data.nodes('sketch/sizes/ts')x(ml)
	
	INSERT INTO @content_list
	  (
	    contents_id,
	    contents_name
	  )
	SELECT	ml.value('@id', 'int'),
			ml.value('@name', 'varchar(100)')
	FROM	@xml_data.nodes('sketch/contents/con')x(ml)
	
	EXEC Products.SketchCard_Add
	     @employee_id = @employee_id,
	     @st_id = @st_id,
	     @kind_id = @kind_id,
	     @subject_id = @subject_id,
	     @descr = @descr,
	     @pic_count = @pic_count,
	     @tech_design = @tech_design,
	     @status_comment = @status_comment,
	     @qp_id = @qp_id,
	     @brand_id = @brand_id,
	     @season_id = @season_id,
	     @pattern_name = @pattern_name,
	     @model_year = @model_year,
	     @art_name = @art_name,
	     @constructor_employee_id = @constructor_employee_id,
	     @ct_id = @ct_id,
	     @content_list = @content_list,
	     @tech_size_list = @tech_size_list,
	     @direction_id = @direction_id,
	     @imt_name = @imt_name,
	     @season_local_id = @season_local_id,
		 @plan_site_dt = @plan_site_dt,
		 @is_china_sample = @is_china_sample
	
	
