CREATE PROCEDURE [Warehouse].[SHKRawMaterialStateGraph_Get]
	@state_src_id INT = NULL,
	@state_dst_id INT = NULL
AS
	SET NOCOUNT ON
	
	SELECT	smsg.state_src_id,
			smsds.state_name state_src_name,
			smsg.state_dst_id,
			smsdd.state_name state_dst_name,
			smsg.dt,
			smsg.employee_id
	FROM	Warehouse.SHKRawMaterialStateGraph smsg   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsds
				ON	smsds.state_id = smsg.state_src_id   
			INNER JOIN	Warehouse.SHKRawMaterialStateDict smsdd
				ON	smsdd.state_id = smsg.state_dst_id
	WHERE	(@state_src_id IS NULL OR smsg.state_src_id = @state_src_id)
			AND	(@state_dst_id IS NULL OR smsg.state_dst_id = @state_dst_id)
	ORDER BY
		smsds.state_name,
		smsdd.state_name