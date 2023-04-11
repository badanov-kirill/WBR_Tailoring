﻿CREATE TABLE [Settings].[Fabricators] (
    [fabricator_id]   INT          IDENTITY (1, 1) NOT NULL,
    [fabricator_name] VARCHAR (50) NOT NULL,
    [INN]             VARCHAR (20) NOT NULL,
    [activ]           INT          NOT NULL,
    CONSTRAINT [PK_fabricator] PRIMARY KEY CLUSTERED ([fabricator_id] ASC)
);


