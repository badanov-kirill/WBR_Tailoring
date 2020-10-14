CREATE TABLE [Planing].[SketchPlanColorVariantCompleting]
(
	spcvc_id              INT IDENTITY(1, 1) CONSTRAINT [PK_SketchPlanColorVariantCompleting] PRIMARY KEY CLUSTERED NOT NULL,
	spcv_id               INT CONSTRAINT [FK_SketchPlanColorVariantCompleting_spcv_id] FOREIGN KEY REFERENCES Planing.SketchPlanColorVariant(spcv_id) NOT NULL,
	completing_id         INT CONSTRAINT [FK_SketchPlanColorVariantCompleting_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	completing_number     TINYINT NOT NULL,
	rmt_id                INT CONSTRAINT [FK_SketchPlanColorVariantCompleting_rmt_id] FOREIGN KEY REFERENCES Material.RawMaterialType(rmt_id) NOT NULL,
	color_id              INT CONSTRAINT [FK_SketchPlanColorVariantCompleting_color_id] FOREIGN KEY REFERENCES Material.ClothColor(color_id) NOT NULL,
	frame_width           SMALLINT NULL,
	okei_id               INT NOT NULL,
	consumption           DECIMAL(9, 3) NULL,
	comment               VARCHAR(300) NULL,
	dt                    dbo.SECONDSTIME NOT NULL,
	employee_id           INT NOT NULL,
	cs_id                 TINYINT CONSTRAINT [PK_SketchPlanColorVariantCompleting_cs_id] FOREIGN KEY REFERENCES Planing.CompletingStatus(cs_id) NOT NULL,
	supplier_id			  INT CONSTRAINT  [FK_SketchPlanColorVariantCompleting_supplier_id] FOREIGN KEY REFERENCES Suppliers.Supplier(supplier_id) NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_SketchPlanColorVariantCompleting_spcv_id_completing_id_completing_number] ON Planing.SketchPlanColorVariantCompleting(spcv_id, completing_id, completing_number) 
ON [Indexes]