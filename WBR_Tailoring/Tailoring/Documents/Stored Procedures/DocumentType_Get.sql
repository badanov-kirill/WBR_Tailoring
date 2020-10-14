CREATE PROCEDURE [Documents].[DocumentType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	dt.doc_type_id,
			dt.doc_type_name
	FROM	Documents.DocumentType dt