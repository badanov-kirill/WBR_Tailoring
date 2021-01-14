CREATE TYPE [Warehouse].[wb_stock_type] AS TABLE (
        subject_name VARCHAR(50) NULL,
        nm_id INT NOT NULL,
        brand_name VARCHAR(50) NULL,
        sa_name VARCHAR(36) NULL,
        ts_name VARCHAR(15) NULL,
        barcode VARCHAR(30) NULL,
        office_name VARCHAR(50) NULL,
        quantity SMALLINT NOT NULL,
        quantity_full SMALLINT NOT NULL,
        quantity_not_in_orders SMALLINT NOT NULL,
        in_way_to_client SMALLINT NOT NULL,
        in_way_from_client SMALLINT NOT NULL,
        days_on_site SMALLINT NOT NULL
                                                 )
GO

GRANT EXECUTE
    ON TYPE::[Warehouse].[wb_stock_type] TO PUBLIC;
GO

