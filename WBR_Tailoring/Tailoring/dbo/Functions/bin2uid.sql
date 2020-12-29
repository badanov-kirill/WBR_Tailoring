CREATE FUNCTION [dbo].[bin2uid]
(
	@bin BINARY(16)
)
RETURNS CHAR(36)

BEGIN
	DECLARE @nguid CHAR(36) = CONVERT(CHAR(36), @bin, 2)
	SET @nguid = SUBSTRING(@nguid, 25, 8) + '-' + SUBSTRING(@nguid, 21, 4) + '-' 
	    +
	    SUBSTRING(@nguid, 17, 4) + '-' +
	    SUBSTRING(@nguid, 1, 4) + '-' + SUBSTRING(@nguid, 5, 12)
	
	RETURN @nguid
END