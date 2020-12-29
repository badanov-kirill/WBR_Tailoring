CREATE TABLE [Logistics].[ShipmentFinishedProductsPrePlanDetail]
(
	sfpppd_id           INT IDENTITY(1, 1) CONSTRAINT [PK_ShipmentFinishedProductsPrePlanDetail] PRIMARY KEY CLUSTERED NOT NULL,
	sfp_id              INT CONSTRAINT [FK_ShipmentFinishedProductsPrePlanDetail_sfp_id] FOREIGN KEY REFERENCES Logistics.ShipmentFinishedProducts(sfp_id) NOT NULL,
	pants_id            INT CONSTRAINT [FK_ShipmentFinishedProductsPrePlanDetail_pants_id] FOREIGN KEY REFERENCES Products.ProdArticleNomenclatureTechSize(pants_id) NOT NULL,
	cnt                 SMALLINT NOT NULL,
	dt                  DATETIME2(0) NOT NULL,
	employee_id         INT NOT NULL,
	start_job_dt        DATETIME2(0) NULL,
	finish_job_dt       DATETIME2(0) NULL,
	problem_job_dt      DATETIME2(0) NULL,
	job_employee_id     INT NULL
)

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ShipmentFinishedProductsPrePlanDetail_sfp_id_pants_id] ON Logistics.ShipmentFinishedProductsPrePlanDetail(sfp_id, pants_id) 
ON [Indexes]