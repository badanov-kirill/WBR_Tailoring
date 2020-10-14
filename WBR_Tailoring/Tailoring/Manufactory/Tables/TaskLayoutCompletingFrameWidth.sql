CREATE TABLE [Manufactory].[TaskLayoutCompletingFrameWidth]
(
	tlcfw_id              INT IDENTITY(1, 1) CONSTRAINT [PK_TaskLayoutCompletingFrameWidth] PRIMARY KEY CLUSTERED NOT NULL,
	tl_id                 INT CONSTRAINT [FK_TaskLayoutCompletingFrameWidth_tl_id] FOREIGN KEY REFERENCES Manufactory.TaskLayout(tl_id) NOT NULL,
	completing_id         INT CONSTRAINT [FK_TaskLayoutCompletingFrameWidth_completing_id] FOREIGN KEY REFERENCES Material.Completing(completing_id) NOT NULL,
	completing_number     TINYINT NOT NULL,
	frame_width           SMALLINT NULL
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaskLayoutCompletingFrameWidth_tl_id_completing_id_completing_number_frame_width] ON Manufactory.TaskLayoutCompletingFrameWidth(tl_id, completing_id, completing_number, frame_width) 
ON [Indexes]