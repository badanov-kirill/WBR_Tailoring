CREATE TABLE [Material].[Cloth]
(
	cloth_id        INT IDENTITY(1, 1) CONSTRAINT [PK_Cloth] PRIMARY KEY CLUSTERED NOT NULL,
	cloth_name      VARCHAR(50) NOT NULL,
	is_deleted      BIT NOT NULL,
	employee_id     INT NOT NULL,
	dt              [dbo].[SECONDSTIME] CONSTRAINT [DF_Cloth_dt] DEFAULT(GETDATE()) NOT NULL,
	ct_id           INT CONSTRAINT [FK_Cloth] FOREIGN KEY REFERENCES Material.ClothType(ct_id) NULL,
)

GO

CREATE UNIQUE NONCLUSTERED INDEX  [UQ_Cloth_cloth_name_ct_id] ON Material.Cloth(cloth_name, ct_id) ON [Indexes]