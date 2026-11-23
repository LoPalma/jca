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

Jca comes with a set of builtins, whose usage and documentation you can find in
a comment before each of their definitions in `jca.sh`.
Here is an example script I used to test them:

````bash
./jca.sh \
  -build '
    if jca_newer main main.c; then
      gcc -Wall -Wextra -Werror -fsanitize=address,undefined main.c -o main  
    fi
  ' \
  -test:build '
    jca_expect 0 "ahoy\n" ./main "ahoy"
    jca_expect 0 "test\n" ./main "test"
    jca_expect 0 "Hello world" ./main
  ' \
  -fuzz:test '
    jca_fuzz 500 1s ./main
  ' > compile.sh && chmod +x compile.sh 

````

## Get JCA
Just `wget` the script from this repo:
````
wget -O jca.sh https://raw.githubusercontent.com/LoPalma/jca/main/jca.sh
````

## Notes

This is not meant as a make/CMake killer. Not at all! It's just my swiss army knife.

---
*This script requires `envsubst` as a dependency, part of gnu gettext shipped by default on most distros*
