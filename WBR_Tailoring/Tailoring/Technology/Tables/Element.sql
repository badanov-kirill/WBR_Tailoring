CREATE TABLE [Technology].[Element]
(
	element_id       INT IDENTITY(1, 1) CONSTRAINT [PK_Element] PRIMARY KEY CLUSTERED NOT NULL,
	element_name     VARCHAR(200) NOT NULL,
	dt               DATETIME2(0) NOT NULL,
	employee_id      INT NOT NULL,
	is_deleted       BIT NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Element_element_name] ON Technology.Element(element_name) WHERE is_deleted = 0 ON [Indexes]
