CREATE PROCEDURE [Material].[RawMaterialIncomeStatusGraph_Get]
	@rmis_src_id INT = NULL,
	@rmis_dst_id INT = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmisg.rmis_src_id,
			rmiss.rmis_name     rmis_src_name,
			rmisg.rmis_dst_id,
			rmisd.rmis_name     rmis_dst_name
	FROM	Material.RawMaterialIncomeStatusGraph rmisg   
			INNER JOIN	Material.RawMaterialIncomeStatus rmiss
				ON	rmiss.rmis_id = rmisg.rmis_src_id   
			INNER JOIN	Material.RawMaterialIncomeStatus rmisd
				ON	rmisd.rmis_id = rmisg.rmis_dst_id
	WHERE	(@rmis_src_id IS NULL OR rmisg.rmis_src_id = @rmis_src_id)
			AND	(@rmis_dst_id IS NULL OR rmisg.rmis_dst_id = @rmis_dst_id)