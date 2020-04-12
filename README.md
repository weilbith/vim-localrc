# Vim Localrc

This plugin attempts to solve the problem of local runtime configurations in the
context of project repositories and similar use-cases. It is a more proper way
of the built-in
[exrc](http://vimdoc.sourceforge.net/htmldoc/options.html#'exrc') feature (see
also [secure](http://vimdoc.sourceforge.net/htmldoc/options.html#'secure')). In
contrast to it, this plugin can load multiple runtime configurations on a path.
This allows to edit files of multiple projects, while the local configurations
only apply to their subtree (require well written local configuration files, see
the section `localrc_usage` in the docs). Moreover is the `exrc` option
considered as not safe. This plugin attempts to solve that problem by letting
the user (visually) confirm a local configuration. Confirmations by the user can
be cached to avoid asking again for the exact same file (determined by hash
values). If a file has been changed since the last confirmation, the user must
verify the file again.

## Installation

Install the plugin with your favorite manager tool. Here is an example using
[dein.vim](https://github.com/Shougo/dein.vim):

```vim
call dein#add('weilbith/vim-localrc')
```

## Usage & Configuration

Checkout the [documentation](./doc/localrc.txt) are accessible via `:help
localrc_usage`. If your plugin manager does not add them automatically you can
do so manually with `:helptags ALL`.
The plugin works out of the box and become active automatically. Nevertheless it
is possible to the plugin by its configuration options. Checkout `:help
localrc_variables` to get an overview.
