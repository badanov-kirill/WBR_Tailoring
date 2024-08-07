﻿CREATE TABLE [Settings].[Fabricators]
(
	[fabricator_id]       INT IDENTITY(1, 1) NOT NULL,
	[fabricator_name]     VARCHAR(50) NOT NULL,
	[INN]                 VARCHAR(20) NOT NULL,
	[activ]               INT NOT NULL,
	[taxation]            INT NULL,
	[token]               VARCHAR(MAX) NULL,
	[EANLogin]            VARCHAR(100) NULL,
	[EANPass]             VARCHAR(100) NULL,
	CZ_ConnectionID        VARCHAR(100) NULL,
	CZ_omsId VARCHAR(100) NULL,
	CZ_Token VARCHAR(3000) NULL,
	СontactPerson VARCHAR(512) NULL,
	CZ_TokenDT DATETIME NULL,
	CONSTRAINT [PK_fabricator] PRIMARY KEY CLUSTERED([fabricator_id] ASC)
);





