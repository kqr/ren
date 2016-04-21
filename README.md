ren
===

`ren` is a simple utility to interactively rename a file in the command line
on Linuxy Unixy systems.


Motivation and Usage
--------------------

Imagine you have a couple of files a fair bit down in the directory tree.
Finally! Finished up all those TPS reports and even included the cover shee...
Damn it! You misspelled the file name. Boss will have your head for this!

No worries, you'll just type this mile long `mv` command where you have to type the
path twice because the relevant directory is not my working directory. You do this
because you're a glutton for punishment.

But wait! You have this new fancy `ren` tool installed. Let's give it a shot.

![animation of ren](screenshots/ren_0.2.0.gif)

The main window shows you the old file name as well as the new one. If the new
path is in red, it means there's a file name collision and `ren` will not allow
you to overwrite an existing file. Change the file name (or path!) to your
hearts' content. If you want to cancel, press escape. When you are done, press
return to confirm.

If you give multiple files as arguments to `ren`, it will prompt you for each
one. If you gave it a million files by accident, and you want to back out,
ctrl-c terminates the program.


Building
--------

```
$ git clone git@github.com:kqr/ren.git
$ cd ren
$ stack setup && stack install
```

`stack` can be installed through the package manager on your system.


