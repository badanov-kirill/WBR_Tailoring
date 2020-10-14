CREATE PROCEDURE [Material].[Completing_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	c.completing_id,
			c.completing_name,
			c.okei_id,
			o.symbol okei_symbol,
			c.check_frame_width,
			c.required_frame_width,
			c.no_check_reserv
	FROM	Material.Completing c   
			INNER JOIN	Qualifiers.OKEI o
				ON	o.okei_id = c.okei_id
	ORDER BY c.completing_name
				