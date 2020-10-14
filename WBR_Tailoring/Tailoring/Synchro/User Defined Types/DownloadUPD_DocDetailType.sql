CREATE TYPE [Synchro].[DownloadUPD_DocDetailType] AS TABLE
(
    esf_id                     INT NOT NULL,
	edo_pos_id                 INT NOT NULL,
	edo_item_name              VARCHAR(1000) NULL,
	edo_okei_code              VARCHAR(4) NULL,
	okei_name                  VARCHAR(15) NULL,
	edo_quantity               DECIMAL(26, 11) NULL,
	edo_price                  DECIMAL(17, 2) NULL,
	edo_item_article           VARCHAR(1000) NULL,
	edo_item_code              VARCHAR(1000) NULL,
	edo_item_spec              VARCHAR(1000) NULL,
	edo_amount_nds             DECIMAL(17, 2) NULL,
	edo_amount_with_nds        DECIMAL(19, 2) NULL,
	edo_amount_without_nds     DECIMAL(19, 2) NULL,
	edo_vat                    DECIMAL(10, 5) NULL,
	edo_gtd                    VARCHAR(1000) NULL,
	edo_country_id             INT NULL
)
GO

GRANT EXECUTE
    ON TYPE::[Synchro].[DownloadUPD_DocDetailType] TO PUBLIC;
GO