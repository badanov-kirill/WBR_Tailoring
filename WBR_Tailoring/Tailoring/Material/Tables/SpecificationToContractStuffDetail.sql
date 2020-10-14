CREATE TABLE [Material].[SpecificationToContractStuffDetail]
(
	stcsd_id              INT CONSTRAINT [PK_SpecificationToContractStuffDetail] PRIMARY KEY CLUSTERED NOT NULL,
	stc_id                INT NOT NULL,
	nomenclature_code     VARCHAR(250) NULL,
	nomenclature_name     VARCHAR(500) NULL,
	stuff_model_id        INT CONSTRAINT [FK_SpecificationToContractStuffDetail_stuff_model_id] FOREIGN KEY REFERENCES Material.SpecificationStuffModel(stuff_model_id) NULL,
	qty                   DECIMAL(15, 3) NOT NULL,
	price                 DECIMAL(15, 2) NULL,
	nds                   TINYINT,
	amount                DECIMAL(15, 2) NULL,
	okei_id               INT NULL,
	receipt_dt            DATE NULL,
	days_before_pay       INT NULL,
	plan_pay_dt           DATE NULL,
	price_with_vat        DECIMAL(15, 2) NULL,
)
GO

CREATE NONCLUSTERED INDEX [IX_SpecificationToContractStuffDetail_stc_id]
ON Material.SpecificationToContractStuffDetail(stc_id) 
ON [Indexes];