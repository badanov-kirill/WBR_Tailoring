CREATE TABLE [Warehouse].[ImprestOtherDetail]
(
	iod_id          INT IDENTITY(1, 1) CONSTRAINT [PK_ImprestOtherDetail] PRIMARY KEY CLUSTERED NOT NULL,
	imprest_id      INT CONSTRAINT [FK_ImprestOtherDetail_imprest_id] FOREIGN KEY REFERENCES Warehouse.Imprest(imprest_id) NOT NULL,
	iod_num         SMALLINT NOT NULL,
	iod_descr       VARCHAR(200) NOT NULL,
	iod_amount      DECIMAL(15, 2) NOT NULL,
	dt              DATETIME2(0) NOT NULL,
	employee_id     INT NOT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ImprestOtherDetail_imprest_id_iod_num] ON Warehouse.ImprestOtherDetail(imprest_id, iod_num) ON [Indexes]