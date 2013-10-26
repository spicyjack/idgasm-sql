-- DDL for a "WAD Index", or a list of filenames and levels contained in one
-- or more "WAD" files, for the video came Doom

-- http://sqlite.org/datatype3.html
-- datatypes: NULL, INTEGER, REAL, TEXT, BLOB

-- date/time functions: http://sqlite.org/lang_datefunc.html

CREATE TABLE files (
    file_id     INTEGER,
    title       TEXT,
    filename    TEXT,
    date_uploaded INTEGER,
);

-- vim: filetype=sql shiftwidth=2 tabstop=2:
