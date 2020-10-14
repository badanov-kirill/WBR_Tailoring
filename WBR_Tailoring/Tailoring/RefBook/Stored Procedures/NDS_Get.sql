CREATE PROCEDURE [RefBook].[NDS_Get]
	@is_deleted BIT = 0
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	n.nds,
			n.is_deleted
	FROM	RefBook.NDS n
	WHERE	@is_deleted IS NULL
			OR	n.is_deleted = @is_deleted 