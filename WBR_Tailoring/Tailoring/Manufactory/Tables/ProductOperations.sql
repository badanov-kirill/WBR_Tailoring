CREATE TABLE [Manufactory].[ProductOperations]
(
	po_id                 INT IDENTITY(1, 1) NOT NULL,
	product_unic_code     INT NOT NULL,
	operation_id          SMALLINT NOT NULL,
	office_id             INT NOT NULL,
	employee_id           INT NOT NULL,
	dt                    [dbo].[SECONDSTIME] CONSTRAINT [DF_ProductOperations_dt] DEFAULT(GETDATE()) NOT NULL,
	is_uniq               BIT NULL,
	CONSTRAINT [PK_ProductOperations] PRIMARY KEY CLUSTERED(po_id ASC),
	CONSTRAINT [FK_ProductOperations_office_id] FOREIGN KEY(office_id) REFERENCES [Settings].[OfficeSetting] (office_id),
	CONSTRAINT [FK_ProductOperations_operation_id] FOREIGN KEY([operation_id]) REFERENCES [Manufactory].[Operation] (operation_id)
);



GO
CREATE NONCLUSTERED INDEX [IX_ProductOperations_dt] ON Manufactory.ProductOperations (operation_id, dt) INCLUDE(product_unic_code, office_id, employee_id) ON 
[Indexes]

GO
CREATE NONCLUSTERED INDEX [IX_ProductOperations_product_unic_code_operation_id] ON Manufactory.ProductOperations (product_unic_code, operation_id) INCLUDE(po_id, dt, employee_id) 
ON [Indexes]

GO
GRANT SELECT
    ON OBJECT::[Manufactory].[ProductOperations] TO [wildberries\olap-orr]
    AS [dbo];

