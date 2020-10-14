CREATE PROCEDURE [Manufactory].[TaskLayoutCompletingFrameWidth_Get]
	@tl_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	tlcfw.tlcfw_id,
			tlcfw.tl_id,
			tlcfw.completing_id,
			c.completing_name,
			tlcfw.completing_number,
			tlcfw.frame_width
	FROM	Manufactory.TaskLayoutCompletingFrameWidth tlcfw   
			INNER JOIN	Material.Completing c
				ON	c.completing_id = tlcfw.completing_id
	WHERE	tlcfw.tl_id = @tl_id
	ORDER BY
		c.completing_id,
		tlcfw.completing_number,
		tlcfw.frame_width