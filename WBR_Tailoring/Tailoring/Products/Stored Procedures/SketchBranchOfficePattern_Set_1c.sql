CREATE PROCEDURE [Products].[SketchBranchOfficePattern_Set_1c]
	@sketch_id INT,
	@office_xml XML,
	@employee_id INT
AS
	DECLARE @tab_office dbo.List
	
	INSERT INTO @tab_office
	  (
	    id
	  )
	SELECT	ml.value('@id', 'int')
	FROM	@office_xml.nodes('root/offc')x(ml)
	
	EXEC Products.SketchBranchOfficePattern_Set
	     @sketch_id = @sketch_id,
	     @tab_office = @tab_office,
	     @employee_id = @employee_id