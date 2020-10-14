CREATE PROCEDURE [Reports].[HistorySketchPlan_GetBySP]
	@sp_id INT
AS
	SET NOCOUNT ON
	
	SELECT	sp.hsp_id,
			sp.employee_id,
			cast(sp.dt AS DATETIME) dt,
			sp.comment,
			ps.ps_name
	FROM	History.SketchPlan sp   
			LEFT JOIN	Planing.PlanStatus ps
				ON	ps.ps_id = sp.ps_id
	WHERE	sp.sp_id = @sp_id