# JCA: bash build system

## brief explaination

As you can check out on my profile, I end up hand-writing long bash scripts to build my projects,
as they're rarely single source. Since CMake is suited for pure C/C++, GNU make is great for turning `.c` into `.o`
but everything else requires endless `.PHONY`, I decided I was going to automate at least most of the
boilerplate of writing shell scripts with jca.

## Usage

This software is pure CLI and prints the final script to stdout.
Suppose you had a very simple project with just a single `main.c` source file:
````bash
./jca.sh \
  -build '
    gcc -o main main.c
  ' \
  -run:build '
    ./main
  ' > compile && chmod +x compile
````
Now, running:
````bash
./compile run
````
Will execute `build` as a dependency.

For longer scripts with user set variables it might be useful to create a `gen.sh` script to
avoid retyping the whole command.

## Get JCA
Just `wget` the script from this repo:
````
wget -O jca.sh https://raw.githubusercontent.com/LoPalma/jca/main/jca.sh
````

## Notes

This is not meant as a make/CMake killer. Not at all! It's just my swiss army knife.
This being said if you plan on using it you can make it track edits using bash's `-nt` check,
and even make it run parallel jobs with `&`/`wait`. It's mostly up to you.

---
*This script requires `envsubst` as a dependency, part of gnu gettext shipped by default on most distros*
