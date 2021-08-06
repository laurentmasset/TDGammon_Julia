# Instalation guide
## 1. Install Python 3.8
Go to https://www.python.org/downloads/ , download Python 3.8 and install it. Don't forget to add pyhton to the PATH environment variable.

## 2. Install Julia
Go to https://julialang.org/downloads/ , download Julia and install it. Don't forget to add julia to the PATH environment variable.

## 3. Configure the Python and Julia
In the project root, open a terminal and run the following commands:
```sh
py -m pip -r requirement.txt
py setup.py
```

# Run a training
To start a training, from the project root, run 
```sh
py tdgammon-cli.py train <options>
```
where \<options> is the required and optional options that are provided. 

Example:
```sh
py tdgammon-cli.py train --type classic --eps 30000 --save_path path\to\save\models --step 1000
```

To have the list of options and their meaning, run  
```sh
py tdgammon-cli.py train -h
```

# Run a test
To start a test, from project root, run
```sh
py tdgammon-cli.py test <options>
```
where \<options> are the required and optional options that are provided.

Example:
```sh
py tdgammon-cli.py test --path path\to\my\models --last 300000 --step 10000 --eps 10000
```

To have the list of options and their meaning,run  
```sh
py tdgammon-cli.py test -h
```

# Help
To find help on the commands available, run
run  
```sh
py tdgammon-cli.py -h
```
or
```sh
py tdgammon-cli.py --help
```
You can contact me at laurentmasset@hotmail.com.