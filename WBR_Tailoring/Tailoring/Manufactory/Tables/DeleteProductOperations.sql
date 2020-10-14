CREATE TABLE [Manufactory].[DeleteProductOperations]
(
	dpo_id                 INT IDENTITY(1, 1) NOT NULL,
	po_id                  INT NOT NULL,
	product_unic_code      INT NOT NULL,
	operation_id           SMALLINT NOT NULL,
	office_id              INT NOT NULL,
	employee_id            INT NOT NULL,
	dt                     dbo.SECONDSTIME NOT NULL,
	delete_employee_id     INT NOT NULL,
	delete_dt              dbo.SECONDSTIME CONSTRAINT [DF_DeleteProductOperations_delete_dt] DEFAULT(GETDATE()) NOT NULL,
	CONSTRAINT [PK_DeleteProductOperations] PRIMARY KEY CLUSTERED(dpo_id ASC)
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DeleteProductOperations_po_id] ON Manufactory.DeleteProductOperations(po_id) ON [Indexes]