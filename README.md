# FilterRename

FilterRename is a CLI tool created for bulk file renaming that work appending a set of micro
operations here called *filters*, which aim to replace most, if not all, the shell commands
usually involved in that kind of operations (*sed*, *awk*, *trim*, ...) in a more safe and
comfortable manner.

[![Ruby](https://github.com/fabiomux/filter_rename/actions/workflows/main.yml/badge.svg)][wf_main]
[![Gem Version](https://badge.fury.io/rb/filter_rename.svg)][gem_version]

## Installation

### Rubygem

Install it as a regular Ruby gem with:
```shell
$ gem install filter_rename
```

## Usage

To simplify the whole process through a command line, the full filename is logically organized
in *targets*:

    <path>/<folder>/<name><ext>

For example, considering the file `/home/fabio/Documents/Ruby/filter_rename/Gemfile.lock` we have:

- path: */home/fabio/Documents/Ruby*
- folder: *filter_rename*
- name: *Gemfile*
- ext: *.lock*

The chain of *filters* will be applied to the current *target*, which is *name* by default, but can
be changed using the *--select* option on the same command line without running the command twice.

For example, to capitalize the *ext* and upper case the *name* at the same time we can use:
```shell
filter_rename Gemfile.lock --uppercase --select ext --capitalize
```

So the file *Gemfile.lock* becomes *GEMFILE.Lock*.

To make things easier we can use a special class of *filters* that target a string as a list of *words*
or *numbers* with their position used as index.

For example, having the files:

    home
      fabio
        Documents
          Photos
            Vacations
              image_from_portofino_0.jpg
              image_from_portofino_1.jpg
              image_from_portofino_2.jpg
              ...

We want:
- space-separated words in place of the underscore;
- the first and third word capitalized;
- the final number must start from 1;
- the final number must be 2 digits wide.

Using:
```shell
$ filter_rename /home/fabio/Documents/Photos/Vacations/*.jpg \
                --spacify '_' \
                --capitalize-word 1:3 \
                --add-number 1,1 \
                --format-number 1,2
```

The result is:

    home
      fabio
        Documents
          Photos
            Vacations
              Image from Portofino 01.jpg
              Image from Portofino 02.jpg
              Image from Portofino 03.jpg
              ...

If you are wondering why all the commands above didn't affected the files physically on the disk,
then must be aware of the three main operations contemplated:
- *preview*: shows the results verbosly without making any change (default);
- *dry-run*: executes a simulation warning also for renaming conflicts;
- *apply*: confirm the changes and rename the files unless the destination file exists.

Last but not least filter_rename also supports *macros* and *regular expressions*, and the ability to
setup configurations params on the fly (*config* and *global*).

## Get help

Where to start
```shell
$ filter_rename --help
```

## More help

More info is available at:
- the [FilterRename GitHub wiki][filter_rename_wiki].


[filter_rename_wiki]: https://github.com/fabiomux/filter_rename/wiki "FilterRename wiki page on GitHub"
[wf_main]: https://github.com/fabiomux/filter_rename/actions/workflows/main.yml
[gem_version]: https://badge.fury.io/rb/filter_rename
