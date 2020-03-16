# FilterRename

FilterRename is a CLI tool created to rename a bunch of files at once applying a cascade of
self-explainatory options called _filters_, in order to substitute all the other shell commands
(like _sed_, _awk_, _trim_, ... ) and personal shell script to achieve that goal safely and
in comfortable manner.

To simplify the whole process through a command line, the full filename is logically organized
in _targets_ like:

    <path>/<folder>/<name><ext>

Considering the file `/home/fabio/Documents/Ruby/filter_rename/Gemfile.lock` we have:

-  __<path>__: */home/fabio/Documents/Ruby*
-  __<folder>__: *filter_rename*
-  __<name>__: *Gemfile*
-  __<ext>__: *.lock*

The chain of filters will be applied to the current _target_ which can be selected using the *--select*
option, the default target is _name_.

## Installation

Install it yourself as:

    $ gem install filter_rename

## Usage

The main concept about FilterRename is the _target_ manipulation with a chain of _filters_
executed one by one as they appear in the argument's list.

There are three main operations:
* _preview_: show the results without make any change (default);
* _dry-run_: executes a simulation warning when a conflict is raised;
* _apply_: confirm the changes and rename the files unless the destination file exists.

Having the files:

    home
      fabio
        Documents
          Photos
            Vacations
              image_portofino_1.jpg
              image_portofino_2.jpg
              image_portofino_3.jpg
              ...

to replace _underscores_ with _spaces_ and _capitalize_ each word let's execute:

    filter_rename /home/fabio/Documents/Photos/Vacations/*.jpg --spacify '_' --capitalize --apply

and the result will be:

    home
      fabio
        Documents
          Photos
            Vacations
              Image Portofino 1.jpg
              Image Portofino 2.jpg
              Image Portofino 3.jpg
              ...


## Get help

Where to start

    $ filter_rename --help

More help

- The wiki page: https://github.com/fabiomux/filter_rename/wiki


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fabio_mux/filter_rename. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

