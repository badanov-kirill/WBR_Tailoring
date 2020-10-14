CREATE PROCEDURE [Warehouse].[Workshop_Get]
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
	SELECT	w.workshop_id,
			w.workshop_name,
			w.place_id
	FROM	Warehouse.Workshop w
