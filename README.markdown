magnum.vim
==========

Magnum is a big integer library for Vim plugins written entirely in Vim
script. Currently it provides just a small set of predicates,
arithmetic, and conversion operations.

This plugin depends on Google's [Maktaba][1] library.

[1]: https://github.com/google/maktaba

Usage
-----

Complete documentation is available at [`:h magnum`][2].

There are a couple of quick usage examples in the wiki, so you can
[click through now][3] to get an impression of what working with
magnum.vim might look like.

[2]: https://github.com/glts/vim-magnum/blob/master/doc/magnum.txt
[3]: https://github.com/glts/vim-magnum/wiki/Usage-examples

Requirements
------------

*   Vim 7.2 or later
*   [Maktaba][1] Vim plugin, version 1.5.0 or later

Installation
------------

Use your preferred installation method.

But keep in mind that magnum.vim depends on [Maktaba][1], so be sure to
install that as well if your plugin manager doesn't handle dependencies
for you.

For example, with [pathogen.vim][4] the installation goes:

    git clone git://github.com/google/maktaba.git ~/.vim/bundle/maktaba
    git clone git://github.com/glts/vim-magnum.git ~/.vim/bundle/magnum

[4]: http://www.vim.org/scripts/script.php?script_id=2332

Development
-----------

There is a test suite written for [vspec][5]. In order to run the tests
all three of vspec, maktaba, and magnum.vim must be on the runtime path.
For example, I use something like the following to run the API tests:

    vspec path/to/{vspec,maktaba,magnum} t/api.vim

[5]: https://github.com/kana/vim-vspec
