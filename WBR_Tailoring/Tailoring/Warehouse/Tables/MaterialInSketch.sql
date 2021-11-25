CREATE TABLE [Warehouse].[MaterialInSketch] (
    [mis_id]                        INT            IDENTITY (1, 1) NOT NULL,
    [sketch_id]                     INT            NOT NULL,
    [task_sample_id]                INT            NOT NULL,
    [shkrm_id]                      INT            NOT NULL,
    [okei_id]                       INT            NOT NULL,
    [qty]                           DECIMAL (9, 3) NOT NULL,
    [stor_unit_residues_okei_id]    INT            NOT NULL,
    [stor_unit_residues_qty]        DECIMAL (9, 3) NOT NULL,
    [dt]                            DATETIME2 (0)  NOT NULL,
    [employee_id]                   INT            NOT NULL,
    [recive_employee_id]            INT            NOT NULL,
    [return_qty]                    DECIMAL (9, 3) NULL,
    [return_stor_unit_residues_qty] DECIMAL (9, 3) NULL,
    [return_dt]                     DATETIME2 (0)  NULL,
    [misd_id]                       INT            NULL,
    CONSTRAINT [PK_MaterialInSketch] PRIMARY KEY CLUSTERED ([mis_id] ASC),
    CONSTRAINT [CH_MaterialInSketch_qty] CHECK ([qty]>(0)),
    CONSTRAINT [CH_MaterialInSketch_su_qty] CHECK ([stor_unit_residues_qty]>(0)),
    CONSTRAINT [FK_MaterialInSketch_misd_id] FOREIGN KEY ([misd_id]) REFERENCES [Warehouse].[MaterialInSketchDoc] ([misd_id]),
    CONSTRAINT [FK_MaterialInSketch_okei_id] FOREIGN KEY ([okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_MaterialInSketch_shkrm_id] FOREIGN KEY ([shkrm_id]) REFERENCES [Warehouse].[SHKRawMaterial] ([shkrm_id]),
    CONSTRAINT [FK_MaterialInSketch_sketch_id] FOREIGN KEY ([sketch_id]) REFERENCES [Products].[Sketch] ([sketch_id]),
    CONSTRAINT [FK_MaterialInSketch_stor_unit_res_okei_id] FOREIGN KEY ([stor_unit_residues_okei_id]) REFERENCES [Qualifiers].[OKEI] ([okei_id]),
    CONSTRAINT [FK_MaterialInSketch_task_sample_id] FOREIGN KEY ([task_sample_id]) REFERENCES [Manufactory].[TaskSample] ([task_sample_id])
);





GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialInSketch_task_sample_id_shkrm_id] ON Warehouse.MaterialInSketch(shkrm_id, task_sample_id) INCLUDE(misd_id) ON [Indexes]

GO 
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MaterialInSketch_task_shkrm_id_return_dt] ON Warehouse.MaterialInSketch(shkrm_id) WHERE return_dt IS NULL ON [Indexes]
GO


