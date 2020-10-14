CREATE PROCEDURE [Planing].[SketchPlanColorVariantCompletingComment_Get]
	@spcvc_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(spcvc.dt AS DATETIME) dt,
			es.employee_name,
			spcvc.comment
	FROM	Planing.SketchPlanColorVariantCompleting spcvc   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = spcvc.employee_id
	WHERE	spcvc.spcvc_id = @spcvc_id
	UNION ALL
	SELECT	CAST(spcvcc.dt AS DATETIME) dt,
			es.employee_name,
			spcvcc.comment
	FROM	Planing.SketchPlanColorVariantCompletingComment spcvcc   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = spcvcc.employee_id
	WHERE	spcvcc.spcvc_id = @spcvc_id
	