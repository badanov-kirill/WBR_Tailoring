CREATE PROCEDURE [Planing].[SketchPrePlanComment_Get]
	@spp_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	CAST(sppc.dt AS DATETIME) dt,
			es.employee_name,
			sppc.comment,
			sppc.spp_id,
			sppc.employee_id
	FROM	Planing.SketchPrePlanComment sppc   
			LEFT JOIN	Settings.EmployeeSetting es
				ON	es.employee_id = sppc.employee_id
	WHERE	sppc.spp_id = @spp_id
	