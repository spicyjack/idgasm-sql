## WADTools Project Notes ##

### App Definition ###
Tool will:
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

vim: filetype=markdown shiftwidth=2 tabstop=2
