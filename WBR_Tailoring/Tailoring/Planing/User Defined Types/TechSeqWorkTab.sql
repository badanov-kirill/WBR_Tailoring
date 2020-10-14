CREATE TYPE [Planing].[TechSeqWork] AS TABLE
(
    id      INT NOT NULL,
    work_dt       DATE NOT NULL,
    work_time     INT NOT NULL,
    office_id	  INT NULL,
    PRIMARY KEY CLUSTERED(id, work_dt)
);
GO

GRANT EXECUTE
    ON TYPE::[Planing].[TechSeqWork] TO PUBLIC;
GO
