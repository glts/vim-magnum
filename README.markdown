magnum.vim
==========

Magnum is a big integer library for Vim plugins written entirely in Vim
script. Currently it provides just a small set of predicates,
arithmetic, and conversion operations. It also includes a simple random
number generator.

Usage
-----

Complete documentation is available at [`:h magnum`][1].

There are a couple of quick usage examples in the wiki, so you can
[click through now][2] to get an impression of what working with
magnum.vim looks like.

[1]: https://github.com/glts/vim-magnum/blob/master/doc/magnum.txt
[2]: https://github.com/glts/vim-magnum/wiki/Usage-examples

Requirements
------------

*   Vim 7.3 or later (Vim 7.2 should also work just fine)

Installation
------------

Use your preferred installation method.

For example, with [pathogen.vim][3] the installation goes simply:

    git clone https://github.com/glts/vim-magnum.git ~/.vim/bundle/magnum

[3]: http://www.vim.org/scripts/script.php?script_id=2332

Development
-----------

There is a test suite written for [vspec][4]. In order to run the tests
both vspec and magnum.vim must be on the runtime path. For example, I
use something like the following to run the API tests:

    path/to/vspec path/to/{vspec,magnum} t/api.vim

[4]: https://github.com/kana/vim-vspec
