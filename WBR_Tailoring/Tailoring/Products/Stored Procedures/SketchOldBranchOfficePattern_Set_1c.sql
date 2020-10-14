CREATE PROCEDURE [Products].[SketchOldBranchOfficePattern_Set_1c]
	@so_id INT,
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
	
	EXEC Products.SketchOldBranchOfficePattern_Set 
	     @so_id = @so_id,
	     @tab_office = @tab_office,
	     @employee_id = @employee_id