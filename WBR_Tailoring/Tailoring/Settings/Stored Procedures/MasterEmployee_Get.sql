CREATE PROCEDURE [Settings].[MasterEmployee_Get]
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	me.employee_id,
			ISNULL(oa.operation_time, 0)     operation_time
	FROM	Settings.MasterEmployee me   
			OUTER APPLY (
			      	SELECT	SUM(sts.operation_time * stsj.plan_cnt) operation_time
			      	FROM	Manufactory.SPCV_TechnologicalSequenceJob stsj   
			      			INNER JOIN	Manufactory.SPCV_TechnologicalSequence sts
			      				ON	sts.sts_id = stsj.sts_id
			      	WHERE	stsj.close_dt IS NULL
			      			AND	stsj.job_employee_id = me.employee_id
			      )                          oa
	WHERE	me.master_employee_id = @employee_id
