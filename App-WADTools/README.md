### `App::WADTools` ###

This Perl module is a set of tools that will index/catalog `WAD` files stored
on the local machine, as well as query the [idGames Archive
API](http://www.doomworld.com/idgames/api) and download different records from
the serivce into a local database file.

The local database files are [SQLite](http://www.sqlite.org/) files that are
generated from [INI](https://metacpan.org/pod/Config::Std) files using a
specific format to describe the tables and columns of the database.

**Scripts included with this distribution:**

**idgames_db_dump**
- Queries the [idGames Archive API](http://www.doomworld.com/idgames/api)
  starting at file ID #1, and up to the latest entry in the `idGames Archive`

**db_bootstrap**
- Creates the [SQLite](http://www.sqlite.org/) database files, which can be
  used with `idgames_archive_db_dump`

**wadindex**
- Creates an index and/or a catalog of files in a local copy of the `idGames
  Archive`.  An index is a mapping of WAD levels to files in the local copy of
  `idGames Archive`, whereas a catalog is a complete listing of resources used
  in a `WAD` file, including vertexes, sectors, textures, sprites and audio.

### Installation ###

To install this module from the source tarball, type the following:

    perl Makefile.PL
    make
    make test
    make install

To install this module from Git, you need to have `Dist::Zilla` installed.
Once `Dist::Zilla` is installed, type the following:

    dzil install

### Dependencies ###

- Perl 5.8.8 or newer (for decent Unicode support)
- The following non-core Perl modules:
  - `Config::Std`
  - `Data::HexDumper`
  - `Date::Format`
  - `DBI`
  - `DBD::SQLite`
  - `File::Find::Rule`
  - `JSON`
  - `Log::Log4perl`
  - `LWP` (The Debian/Ubuntu package for this module is usually called
    `libwww-perl`, and for Fedora/Red Hat/Centos, `perl-libwww-perl`)
  - `Moo`
  - `XML::Fast`
  - `strictures`

If the above list of dependencies is daunting, and you're on a UNIX machine,
consider installing Perlbrew (http://perlbrew.pl/).  Perlbrew installs a local
copy of Perl in your home directory, along with a bunch of Perl tools that
make things super easy for installing Perl module dependencies.

    # install Perlbrew
    curl -L http://install.perlbrew.pl | bash

    # install a Perl, this will install the latest stable release
    perlbrew install perl-5.18.1

    # install 'cpanm'
    perlbrew install-cpanm

    # install required non-core modules
    cpanm <list of modules from above>

    # go get your favorite beverage, sit back and enjoy while 'cpanm' 
    # installs your list of modules

`cpanm` is also available with Strawberry Perl on Windows.

### Contact info ###

* Website: https://github.com/spicyjack/wadtools
* Bug reports: https://github.com/spicyjack/wadtools/issues

### Copyright and License ###

Copyright (C) 2013 by Brian Manning `<brian {at} xaoc {dot} org>`

License for Perl scripts in the `bin/` and `t/` directories of this
distribution:

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation, version 2 
    of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

The full text of version 2 of the GNU GPL is located at:
http://www.gnu.org/licenses/old-licenses/gpl-2.0.html

License for Perl modules in the `lib/` directory of this distribution:

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; version 2.1 
    of the License.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

The full text of version 2.1 of the GNU LGPL is located at:
http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html

vim: filetype=markdown shiftwidth=2 tabstop=2
