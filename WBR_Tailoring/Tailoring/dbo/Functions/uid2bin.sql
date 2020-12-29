CREATE FUNCTION [dbo].[uid2bin]
(
	@uid CHAR(36)
)
RETURNS BINARY(16)

BEGIN
	DECLARE @v_ret BINARY(16)
	
	SET @v_ret = CONVERT(
	        BINARY(16),
	        SUBSTRING(@uid, 20, 4) + SUBSTRING(@uid, 25, 12) + SUBSTRING(@uid, 15, 4) 
	        + SUBSTRING(@uid, 10, 4) + SUBSTRING(@uid, 1, 8),
	        2
	    )
	
	RETURN @v_ret
END