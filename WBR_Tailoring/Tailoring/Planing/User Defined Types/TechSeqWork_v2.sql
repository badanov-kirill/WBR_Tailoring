CREATE TYPE [Planing].[TechSeqWork_v2] AS TABLE
(
	id INT NOT NULL,
	work_dt DATE NOT NULL,
	employee_id INT NOT NULL,
	office_id INT NOT NULL,
	work_time INT NOT NULL,
	PRIMARY KEY CLUSTERED(id, work_dt, employee_id, office_id)
);
GO

GRANT EXECUTE
    ON TYPE::[Planing].[TechSeqWork_v2] TO PUBLIC;
GO
