CREATE TABLE [Material].[RawMaterialIncome] (
    [doc_id]              INT             NOT NULL,
    [doc_type_id]         TINYINT         NOT NULL,
    [rmis_id]             INT             NOT NULL,
    [dt]                  DATETIME2 (0)   NOT NULL,
    [employee_id]         INT             NOT NULL,
    [rv]                  ROWVERSION      NOT NULL,
    [supplier_id]         INT             NOT NULL,
    [suppliercontract_id] INT             NOT NULL,
    [supply_dt]           DATE            NOT NULL,
    [is_deleted]          BIT             NOT NULL,
    [goods_dt]            DATE            NULL,
    [comment]             VARCHAR (200)   NULL,
    [payment_comment]     VARCHAR (200)   NULL,
    [plan_sum]            DECIMAL (18, 2) NULL,
    [scan_load_dt]        DATETIME2 (0)   NULL,
    [reserv_close_dt]     DATETIME2 (0)   NULL,
    [ots_id]              INT             NULL,
    [company_id]          INT             NULL,
    [fabricator_id]       INT             NOT NULL,
    CONSTRAINT [PK_RawMaterialIncome] PRIMARY KEY CLUSTERED ([doc_id] ASC, [doc_type_id] ASC),
    CONSTRAINT [CH_RawMaterialIncome_doc_type_id] CHECK ([doc_type_id]=(1)),
    CONSTRAINT [FK_RawMaterialIncome_company_id] FOREIGN KEY ([company_id]) REFERENCES [RefBook].[Company] ([company_id]),
    CONSTRAINT [FK_RawMaterialIncome_doc_id_doc_type_id] FOREIGN KEY ([doc_type_id], [doc_id]) REFERENCES [Documents].[DocumentID] ([doc_type_id], [doc_id]),
    CONSTRAINT [FK_RawMaterialIncome_fabricator_id] FOREIGN KEY ([fabricator_id]) REFERENCES [Settings].[Fabricators] ([fabricator_id]),
    CONSTRAINT [FK_RawMaterialIncome_ots_id] FOREIGN KEY ([ots_id]) REFERENCES [Material].[OrderToSupplier] ([ots_id]),
    CONSTRAINT [FK_RawMaterialIncome_rmis_id] FOREIGN KEY ([rmis_id]) REFERENCES [Material].[RawMaterialIncomeStatus] ([rmis_id])
);






GO


