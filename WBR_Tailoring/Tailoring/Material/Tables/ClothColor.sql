CREATE TABLE [Material].[ClothColor] (
    [color_id]   INT          NOT NULL,
    [color_name] VARCHAR (50) NOT NULL,
    [color_cod]  INT          NULL,
    CONSTRAINT [PK_ClothColor] PRIMARY KEY CLUSTERED ([color_id] ASC)
);



GO
GRANT SELECT
    ON OBJECT::[Material].[ClothColor] TO [wildberries\olap-orr]
    AS [dbo];

