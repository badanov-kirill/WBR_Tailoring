CREATE TABLE [RefBook].[Offices]
(
	office_id SMALLINT IDENTITY(1,1) CONSTRAINT [PK_Offices] PRIMARY KEY CLUSTERED NOT NULL,
	office_name VARCHAR(50) NOT NULL
)

GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Offices_office_name] ON RefBook.Offices(office_name) INCLUDE(office_id) ON [Indexes]