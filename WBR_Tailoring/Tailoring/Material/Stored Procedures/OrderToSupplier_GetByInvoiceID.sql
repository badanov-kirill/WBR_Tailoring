CREATE PROCEDURE [Material].[OrderToSupplier_GetByInvoiceID]
	@rmi_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SELECT	rmi.rmi_id,
			rmic.ots_id
	FROM	Material.RawMaterialInvoice rmi   
			INNER JOIN	Material.RawMaterialIncome rmic
				ON	rmic.doc_id = rmi.doc_id
				AND	rmic.doc_type_id = rmi.doc_type_id
	WHERE	rmi.rmi_id = @rmi_id