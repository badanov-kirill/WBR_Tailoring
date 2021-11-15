CREATE TABLE [Manufactory].[CuttingActual] (
    [ca_id]        INT                 IDENTITY (1, 1) NOT NULL,
    [cutting_id]   INT                 NOT NULL,
    [actual_count] SMALLINT            NOT NULL,
    [dt]           [dbo].[SECONDSTIME] NOT NULL,
    [employee_id]  INT                 NOT NULL,
    CONSTRAINT [PK_CuttingActual] PRIMARY KEY CLUSTERED ([ca_id] ASC),
    CONSTRAINT [FK_CuttingActual_cutting_id] FOREIGN KEY ([cutting_id]) REFERENCES [Manufactory].[Cutting] ([cutting_id])
);





GO
CREATE NONCLUSTERED INDEX [IX_CuttingActual_cutting_id] ON Manufactory.CuttingActual(cutting_id) INCLUDE(actual_count) ON [Indexes]

GO


