CREATE PROCEDURE [Manufactory].[SampleType_Get]
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	st.st_id,
			st.st_name
	FROM	Manufactory.SampleType st