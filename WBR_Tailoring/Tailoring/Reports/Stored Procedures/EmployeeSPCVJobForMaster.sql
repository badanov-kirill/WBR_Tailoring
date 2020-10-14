CREATE PROCEDURE [Reports].[EmployeeSPCVJobForMaster]
	@employee_id INT = NULL
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	SELECT	stsj.job_employee_id,
			SUM(stsj.plan_cnt) plan_cnt,
			SUM(sts.operation_time * stsj.plan_cnt) operation_time
	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
				ON	sts.sts_id = stsj.sts_id
	WHERE	stsj.employee_cnt IS NULL
			AND	stsj.close_dt IS NULL
			AND	(
			   		@employee_id IS NULL
			   		OR EXISTS (
			   		   	SELECT	1
			   		   	FROM	Settings.MasterEmployee me
			   		   	WHERE	me.employee_id = stsj.job_employee_id
			   		   			AND	me.master_employee_id = @employee_id
			   		   )
			   	)
	GROUP BY
		stsj.job_employee_id