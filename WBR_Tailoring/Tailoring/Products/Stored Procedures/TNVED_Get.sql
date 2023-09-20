CREATE PROCEDURE [Products].[TNVED_Get]
	@tnved_id  INT = NULL,
	@tnved_cod VARCHAR(20) = NULL
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT  d.tnved_id,
	d.tnved_cod,
	d.tnved_desc
	FROM	Products.TNVED d
	WHERE	(@tnved_id IS NULL
			OR	d.tnved_id = @tnved_id)
			AND  (@tnved_cod IS NULL
			OR	d.tnved_cod like concat(@tnved_cod,'%'))
	order by d.tnved_cod