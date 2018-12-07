## WADTools Project Notes ##

Perl module dependencies for `wadindex`
- _strictures_
- _Data::Hexdumper_
- _Digest::CRC_
- _Math::BaseCalc_
- _IO::Interactive_

### App Definition ###
WADTools will be able to:
- Read WAD file
- Parse WAD directory structure, looking for levels (for indexing), and
  textures/things (for cataloging)
- Write out binary format index file when requested
- Write out a catalog file/database when requested
- See `mayhem/docs.git/mayhem.md` for more info on the Indexer and Cataloger

Indexer definition
- Counts number of levels in a WAD
- Determines what game the WAD is for (by level number, and/or things in WAD)
- Determines WAD checksum
  - Stores checksum in database, in order to be able to find duplicate files

Indexer keeps track of:
- `filename` (1)
- `dir` (1)
- `author` (1)
- `checksum`
- `rating` (1)
- `votes` (1)
- `levels`

Note 1: info will be obtained from idGames Archive for files indexed from
idGames Archive

Cataloger
- Everything the **Indexer** above does
- Number of lumps in a WAD
- Number of things in a WAD
- Number of linedefs/sidedefs/vertexes/nodes

See also `mayhem/docs.git/idgames_stats.md` for more ideas on what could be
cataloged.

Tokenizer
- Goes through all of the fields, and creates a tokenized index database of
  words in `/idgames` entries
  - Tokenizes whole words, as well as first 1, 2, 3, 4, 5 characters
- Exports a database of tokenized values to be used in local/offline searches
  from a client app

### SQLite links ###
Helpful links for SQL-type things:
- SQLite3 Datatypes: http://sqlite.org/datatype3.html
  - available datatypes: NULL, INTEGER, REAL, TEXT, BLOB
- date/time functions: http://sqlite.org/lang_datefunc.html
- `ON CONFLICT` clause: http://www.sqlite.org/lang_conflict.html
- `UNIQUE` contstraints:
  http://www.sqlite.org/lang_createtable.html#uniqueconst

### Where to find files to index/catalog ###
- WAD Search Object (**wad.so**)
  - Master index
  - Keeps track of files found at:
    - idGames Archive on **Doomworld**
    - Individual shovelware CDs on **archive.org**

### wad.so Site description ###
- Allows for searching by filename
- Returns a list of short URLs to the sites that have a copy of that file
  - List has file size of the files for comparison
  - List files that have checksums in the database as being cataloged/indexed
  - Add a special icon in the listings for Cacoward recipients

Typical workflow for indexing/cataloging
- Download files/CD ISO
- Catalog/index files
- Add catalog/index info to database
  - idGames Archive info gets it's own database
  - Create databases for each shovelware CD
  - Create a "master database", which stores:
    - `filename`
    - `checksum`
    - Title?
    - `wad.so` short URL
    - Which database can be queried for more information

vim: filetype=markdown shiftwidth=2 tabstop=2
