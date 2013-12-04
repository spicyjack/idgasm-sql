## WAD Tools ##

A bunch of tools that interact with WAD files from the games 
Doom/Doom II/Heretic/Hexen/Strife and others.

There's also a set of tools that will interact with the `Doomworld idGames
Archive` (located at http://www.doomworld.com/idgames), which is a web front
end to the actual `idGames Archive` FTP/HTTP service.

## What's in this repo? ##

### App::WADTools ###
The Perl distribution `App::WADTools` is a set of tools that can index/catalog
`WAD` files, as well as query the [idGames Archive
API](http://www.doomworld.com/idgames/api) and download different
records from the serivce into a local database file.

The local database files are [SQLite](http://www.sqlite.org/) files that are
generated from [INI](https://metacpan.org/pod/Config::Std) files using a
specific format.

Scripts in the `bin/` directory of this distribution:

`idgames_archive_db_dump` - Queries the [idGames Archive
API](http://www.doomworld.com/idgames/api) starting at file ID #1, and up to
the latest entry in the `idGames Archive`

`db_bootstrap` - Creates the [SQLite](http://www.sqlite.org/) database files,
which can be used with `idgames_archive_db_dump`

`wadindex` - Creates an index and/or a catalog of files in a local copy of the
`idGames Archive`.  An index is a mapping of WAD levels to files in the local
copy of `idGames Archive`, whereas a catalog is a complete listing of
resources used in a `WAD` file, including vertexes, sectors, textures, sprites
and audio.

### `scripts` Directory ###
- `sum_all_text_files.sh` - sums all of the text files in directories known to
  contain WAD files

vim: filetype=markdown shiftwidth=2 tabstop=2
