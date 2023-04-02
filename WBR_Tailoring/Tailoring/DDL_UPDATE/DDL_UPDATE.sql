INSERT INTO [Settings].[Fabricators] ([fabricator_name],[INN],[activ])VALUES ('OOO ''Василиса''','9723096830',1);
INSERT INTO [Settings].[Fabricators] ([fabricator_name],[INN],[activ])VALUES ('OOO ''Мангуст-Т''','-',0);

Alter table Planing.SketchPlan add  sew_fabricator_id  int;
UPDATE Planing.SketchPlan SET sew_fabricator_id = 1 WHERE sew_fabricator_id is null;
ALTER TABLE [Planing].[SketchPlan]  WITH CHECK ADD CONSTRAINT [FK_SketchPlan_sew_fabricator_id] FOREIGN KEY([sew_fabricator_id ]) REFERENCES [Settings].[Fabricators] (fabricator_id);


Alter table Planing.SketchPlanColorVariant add  sew_fabricator_id  int;
UPDATE Planing.SketchPlanColorVariant SET sew_fabricator_id = 1 WHERE sew_fabricator_id is null;
ALTER TABLE [Planing].[SketchPlanColorVariant]  WITH CHECK ADD  CONSTRAINT  [FK_SketchPlanColorVariant_sew_fabricator_id] FOREIGN KEY([sew_fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id])
ALTER TABLE[Planing].[SketchPlanColorVariant]  ALTER COLUMN sew_fabricator_id INTEGER NOT NULL;

Alter table Warehouse.SHKRawMaterialActualInfo add fabricator_id  int;
UPDATE Warehouse.SHKRawMaterialActualInfo SET fabricator_id = 1 WHERE fabricator_id is null;
ALTER TABLE [Warehouse].[SHKRawMaterialActualInfo]  WITH CHECK ADD  CONSTRAINT [FK_SHKRawMaterialActualInfok_fabricator_id] FOREIGN KEY([fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id]);
ALTER TABLE [Warehouse].[SHKRawMaterialActualInfo] ALTER COLUMN fabricator_id INTEGER NOT NULL;

Alter table Material.RawMaterialIncome add fabricator_id  int;
ALTER TABLE Material.RawMaterialIncome  WITH CHECK ADD  CONSTRAINT [FK_RawMaterialIncome_fabricator_id] FOREIGN KEY([fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id])
UPDATE Material.RawMaterialIncome SET fabricator_id = 1 WHERE fabricator_id is null;
ALTER TABLE Material.RawMaterialIncome ALTER COLUMN fabricator_id INTEGER NOT NULL

Alter table History.RawMaterialIncome add fabricator_id  int;
Alter table History.SketchPlanColorVariant add  sew_fabricator_id  int;
Alter table History.SHKRawMaterialActualInfo add fabricator_id  int;

Alter table Manufactory.EANCode add fabricator_id  int;
UPDATE Manufactory.EANCode SET fabricator_id = 1 WHERE fabricator_id is null;
ALTER TABLE Manufactory.EANCode ALTER COLUMN fabricator_id INTEGER NOT NULL;
ALTER TABLE [Manufactory].[EANCode] DROP CONSTRAINT [PK_EANCode] ;
ALTER TABLE [Manufactory].[EANCode] ADD  CONSTRAINT [PK_EANCode] PRIMARY KEY CLUSTERED ([pants_id],[fabricator_id]);
ALTER TABLE Manufactory.EANCode WITH CHECK ADD  CONSTRAINT [FK_EANCode_fabricator_id] FOREIGN KEY([fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id]);

Alter table Synchro.ProductsForEAN add fabricator_id  int;
UPDATE Synchro.ProductsForEAN SET fabricator_id = 1 WHERE fabricator_id is null;
ALTER TABLE Synchro.ProductsForEAN ALTER COLUMN fabricator_id INTEGER NOT NULL;
ALTER TABLE Synchro.ProductsForEAN DROP CONSTRAINT [PK_ProductsForEAN] ;
ALTER TABLE Synchro.ProductsForEAN ADD  CONSTRAINT [PK_ProductsForEAN] PRIMARY KEY CLUSTERED ([pants_id],[fabricator_id]);
ALTER TABLE Synchro.ProductsForEAN WITH CHECK ADD CONSTRAINT [FK_ProductsForEAN_fabricator_id] FOREIGN KEY([fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id]);

Alter table Synchro.ProductsForEANCnt add fabricator_id  int;
UPDATE Synchro.ProductsForEANCnt SET fabricator_id = 1 WHERE fabricator_id is null;
ALTER TABLE Synchro.ProductsForEANCnt ALTER COLUMN fabricator_id INTEGER NOT NULL;
ALTER TABLE Synchro.ProductsForEANCnt DROP CONSTRAINT [PK_ProductsForEANCnt] ;
ALTER TABLE Synchro.ProductsForEANCnt ADD  CONSTRAINT [PK_ProductsForEANCnt] PRIMARY KEY CLUSTERED ([pants_id],[fabricator_id]);
ALTER TABLE Synchro.ProductsForEANCnt WITH CHECK ADD  CONSTRAINT [FK_ProductsForEANCnt_fabricator_id] FOREIGN KEY([fabricator_id ]) REFERENCES [Settings].[Fabricators] ([fabricator_id]);

/*
--INSERT INTO Synchro.ProductsForEAN
+PROCEDURE [Manufactory].[CoveringInfoByProdUnicCode]
+PROCEDURE [Planing].[Covering_Add]
+PROCEDURE [Planing].[Covering_CostSet]
+PROCEDURE [Planing].[SketchPlanColorVariant_AddForBranding]
+PROCEDURE [Products].[ProdArticleNomenclatureTS_GetByID]

--INSERT INTO Synchro.ProductsForEANCnt 
+PROCEDURE [Synchro].[ProductsForEAN_GetForCreate]
PROCEDURE [Synchro].[ProductsForEAN_GetForCreate2]
+PROCEDURE [Synchro].[ProductsForEAN_GetForPub]
PROCEDURE [Synchro].[ProductsForEAN_GetForPub2]


*/


















