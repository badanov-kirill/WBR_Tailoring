CREATE TABLE [Material].[Completing]
(
	completing_id            INT IDENTITY(1, 1) CONSTRAINT [PK_Completing] PRIMARY KEY CLUSTERED NOT NULL,
	completing_name          VARCHAR(100) NOT NULL,
	okei_id                  INT CONSTRAINT [FK_Completing] FOREIGN KEY REFERENCES Qualifiers.OKEI(okei_id) NOT NULL,
	dt                       dbo.SECONDSTIME NOT NULL,
	employee_id              INT NOT NULL,
	visible_queue            SMALLINT NOT NULL,
	check_frame_width        BIT NOT NULL,
	required_frame_width     BIT NOT NULL,
	no_check_reserv			 BIT NOT NULL
)
