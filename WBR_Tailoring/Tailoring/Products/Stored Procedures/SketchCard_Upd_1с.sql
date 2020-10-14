CREATE PROCEDURE [Products].[SketchCard_Upd_1с]
	@sketch_id INT,
	@employee_id INT,
	@kind_id INT = NULL,
	@descr VARCHAR(1000) = NULL,
	@pic_count TINYINT = NULL,
	@tech_design BIT = NULL,
	@status_comment VARCHAR(250) = NULL,
	@qp_id TINYINT = NULL,
	@pattern_name VARCHAR(15) = NULL,
	@constructor_employee_id INT = NULL,
	@style_id INT = NULL,
	@ct_id INT = NULL,
	@wb_size_group_id INT = NULL,
	@xml_data XML = NULL,
	@rv_bigint VARCHAR(19),
	@is_deleted BIT = NULL,
	@imt_name VARCHAR(100) = NULL,
	@sa VARCHAR(15) = NULL,
	@sa_local VARCHAR(15) = NULL,
	@model_year SMALLINT = NULL,
	@season_local_id INT = NULL,
	@plan_site_dt DATE = NULL,
	@is_china_sample BIT = 0,
	@construction_sale BIT = 0,
	@subject_id INT = NULL
AS
	SET NOCOUNT ON
	DECLARE @content_list Products.ContentList 
	DECLARE @tech_size_list dbo.List 
	DECLARE @rv_bigint_loc     BIGINT = CAST(@rv_bigint AS BIGINT)
	DECLARE @tab_modify        BIT = CASE 
	                                      WHEN @xml_data IS NULL THEN 0
	                                      ELSE 1
	                                 END
	
	IF @tab_modify = 1
	BEGIN
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
	END
	
	EXEC Products.SketchCard_Upd
	     @sketch_id = @sketch_id,
	     @employee_id = @employee_id,
	     @kind_id = @kind_id,
	     @descr = @descr,
	     @pic_count = @pic_count,
	     @tech_design = @tech_design,
	     @status_comment = @status_comment,
	     @qp_id = @qp_id,
	     @pattern_name = @pattern_name,
	     @constructor_employee_id = @constructor_employee_id,
	     @style_id = @style_id,
	     @ct_id = @ct_id,
	     @wb_size_group_id = @wb_size_group_id,
	     @content_list = @content_list,
	     @tech_size_list = @tech_size_list,
	     @rv_bigint = @rv_bigint_loc,
		 @is_deleted = @is_deleted,
		 @tech_size_modify = @tab_modify,
		 @content_modify = @tab_modify,
		 @imt_name = @imt_name,
		 @sa = @sa,
		 @sa_local = @sa_local,
		 @model_year = @model_year,
		 @season_local_id = @season_local_id,
		 @plan_site_dt = @plan_site_dt,
		 @is_china_sample = @is_china_sample,
		 @construction_sale = @construction_sale,
		 @subject_id = @subject_id