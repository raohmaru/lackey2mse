# Lackey set to MSE2 set file converter

A command line tool to convert Dvorak decks in Lackey format to a Magic Set Editor 2 set file.

Find Dvorak decks at http://www.dvorakgame.co.uk/index.php/Main_Page
Magic Set Editor 2 template: https://github.com/raohmaru/generic-mse2-template

## Usage
`lackey2mse2 FILE [options] [set options]`

Examples:
```
lackey2mse2 lackey.txt
lackey2mse2 lackey.txt -n "My deck" -c PRG
lackey2mse2 lackey.txt -l "Event:#666666;Human:125,5,1"
lackey2mse2 lackey.txt -f -o ../decks/mydeck
```

Arguments:

`FILE                Input file representing a set definition of an Dvorak deck in Lackey format`

Options:
```
-h, --help          Display this information.
-v, --version       Display version number and exit.
-f, --force         Overwrites output file without asking for permission
-d, --dry-run       Run without generating the output file
```

Set options:
```
-n, --name WORDS    Name of the set
-c, --code WORD     Code of the set
-o, --output PATH   Output file name or directory
-l, --colors LIST   A list of colors for each type or subtype
					"Type1:hex or rgb;Subtype2:hex or rgb"
```

## License

Released under the MIT License.