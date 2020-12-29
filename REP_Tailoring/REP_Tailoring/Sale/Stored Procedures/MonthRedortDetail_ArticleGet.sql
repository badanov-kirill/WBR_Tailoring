CREATE PROCEDURE [Sale].[MonthRedortDetail_ArticleGet]
	@realizationreport_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	DISTINCT sa.sa_name
	FROM	Sale.MonthReportDetail mrd   
			INNER JOIN	Products.SupplierArticle sa
				ON	sa.sa_id = mrd.sa_id
	WHERE	mrd.realizationreport_id = @realizationreport_id