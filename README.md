![Godot Audio Manager](https://github.com/MathewHDYT/Godot-Data-Manager-GDM/blob/main/logo.png/)

[![MIT license](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://lbesson.mit-license.org/)
[![Godot](https://img.shields.io/badge/Godot-2%2B-green.svg?style=flat-square)](https://docs.godotengine.org/en/stable/index.html)
[![GitHub release](https://img.shields.io/github/release/MathewHDYT/Godot-Data-Manager-GDM/all.svg?style=flat-square)](https://github.com/MathewHDYT/Godot-Data-Manager-GDM/releases/)
[![GitHub downloads](https://img.shields.io/github/downloads/MathewHDYT/Godot-Data-Manager-GDM/all.svg?style=flat-square)](https://github.com/MathewHDYT/Godot-Data-Manager-GDM/releases/)

# Godot Data Manager (GDM)
Used to create, manage and load data via. files on the system easily and permanently over multiple game sessions. 

## Contents
- [Godot Data Manager (GDM)](#godot-data-manager-gdm)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Installation](#installation)
- [Documentation](#documentation)
  - [Reference to Data Manager Script](#reference-to-data-manager-script)
  - [Adding new AutoLoad properties](#adding-new-autoload-properties)
  - [Possible Errors](#possible-errors)
  - [Public accesible methods](#public-accesible-methods)
  	- [Create New File method](#create-new-file-method)
  	- [Read From File method](#read-from-file-method)
  	- [Change File Path method](#change-file-path-method)
  	- [Update File Content method](#update-file-content-method)
  	- [Append File Content method](#append-file-content-method)
  	- [Compare Hash method](#compare-hash-method)
  	- [Delete File method](#delete-file-method)

## Introduction
A lot of games need to save data between multiple game runs, this small and easily integrated Data Manager can help you create, manage and load data via. files on the system easily and permanently over multiple game sessions.

**Godot Data Manager implements the following methods consisting of a way to:**
- Create and register a new file with the Data Manager and the given settings at the given location (see [Create New File method](#create-new-file-method))
- Read the content of a registered file (see [Read From File method](#read-from-file-method))
- Change the file path of a registered file (see [Change File Path method](#change-file-path-method))
- Change all the content inside of a registered file (see [Update File Content method](#update-file-content-method))
- Append content to a registered file (see [Append File Content method](#append-file-content-method))
- Compare the file hash of a registered file with the expected hash (see [Compare Hash method](#compare-hash-method))
- Delete a registered file and unregister it (see [Delete File method](#delete-file-method))

For each method there is a description on how to call it and how to use it correctly for your game in the given section.

## Installation
- [Godot](https://godotengine.org/download/windows) Ver. 2.0

The Data Manager itself is version independent, as long as the [```File```](https://docs.godotengine.org/en/stable/classes/class_file.html) object already exists. Additionally the example project can be opened with Godot itself or the newest release can be downloaded and exectued to test the functionality.

If you prefer the first method, you can simply install the shown Godot version and after installing it you can download the project and open it in Godot. Then you can start the game with the play button to test the DataManagers functionality.

To simply use the Data Manager in your own project without downloading the Godot project get the file in the **addons/GodotDataManager/Scripts/** called ```DataManager.gd``` or alternatively get it from the newest release (may not include the newest changes) and save it in your own project. Then add it into the ```AutoLoad``` property like shown in [Adding new AutoLoad properties](#adding-new-autoload-properties).

# Documentation
This documentation strives to explain how to start using the Data Manager in your project and explains how to call and how to use its publicly accesible methods correctly.

## Reference to Data Manager Script
To use the Data Manager to start creating/reading files outside of itself you need to reference it. As the Data Manager is a ```Singelton``` this can be done easily when we save the script into our Autload properties like shown in [Adding new AutoLoad properties](#adding-new-autoload-properties). After this is done they can be simply called like this.

```gdscript
func _ready()
    DataManager.create_new_file("fileName")
```

## Adding new AutoLoad properties
To add a new ```AutoLoad``` property, you simply need to click the add button and choose the Data Manager and given them the name you want to acces them with.

![Image of Autoload property](https://image.prntscr.com/image/CscPCmKIREa2D759lnIxhQ.png)

## Possible Errors

| **ID** | **CONSTANT**                  | **MEANING**                                                                                    |
| -------| ------------------------------| -----------------------------------------------------------------------------------------------|
| 0      | OK                            | Method succesfully executed                                                                    |
| 9      | ERR_FILE_BAD_PATH             | Given path does not exists in the local system                                                 |
| 15     | ERR_FILE_UNRECOGNIZED         | File has not been registered with the create file function yet                                 |
| 16     | ERR_FILE_CORRUPT              | File has been changed outside of the environment, accessing might not be save anymore          |
| 17     | ERR_FILE_MISSING_DEPENDENCIES | Tried to compare hash, but hasing has not been enabled for the registered file                 |
| 26     | ERR_CANT_RESOLVE              | Could not delete file as the entry does not exists in the dictionary anymore                   |
| 31     | ERR_INVALID_PARAMETER         | Can not both encrypt and compress a file                                                       |
| 32     | ERR_ALREADY_EXISTS            | A file already exists at the same path, choose a different name or directory                   |
| 33     | ERR_DOES_NOT_EXIST            | There is no file with the given name in the given directory, ensure it wasn't moved or deleted |

## Public accesible methods
This section explains all public accesible methods, especially what they do, how to call them and when using them might be advantageous instead of other methods. We always assume Data Manager instance has been already referenced in the script. If you haven't done that already see [Reference to Data Manager Script](#reference-to-data-manager-script).

### Create New File method
**What it does:**
Creates and registers a new file with the given properties, writes the given text to it and returns an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how creating the file failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the file we want to register and create
- ```Content``` is the inital data that is saved into the file
- ```DirectoryPath``` is the directory the file should be saved into
- ```FileEnding``` is the extension the file should have
- ```Encryption``` decides wether the given file should be encrypted or not
- ```Hashing``` decides wether the given file should be checked for unexpected changes before using it
- ```Compression``` decides wheter and with wich compression algorithm the given file should be compressed or not

```gdscript
var file_name := "save"
var content := ""
var directory_path := "user://"
var file_ending := ".txt"
var encryption := false
var hashing := false
var compression := File.COMPRESSION_GZIP
var err := DataManager.create_new_file(file_name, content, directory_path, file_ending, encryption, hashing, compression)
if (err != OK):
    print("Creating file failed with error id: ", err)
else:
    print("Creating file succesfull")
```

Alternatively you can call the methods with less paramters as some of them have default arguments.

```gdscript
var file_name := "save"
var err := DataManager.create_new_file(file_name)
if (err != OK):
    print("Creating file failed with error id: ", err)
else:
    print("Creating file succesfull")
```

**When to use it:**
When you want to register and create a new file with the system so it can be used later.

### Read From File method
**What it does:**
Returns an instance of the ValueError class, where the value (gettable with ```get_value()```), is the text from a registered file, that is an empty string, when the file is not yet registered or when the hash is not as expected, if hashing is enabled for the registered file in the [Create New File method](#create-new-file-method) and where the error (gettable with ```get_error()```) is an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how reading the file failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to read now

```gdscript
var file_name := "save"
var result := DataManager.read_from_file(file_name)
print(result.get_value())
var err := result.get_error()
if (err != OK):
    print("Reading file failed with error id: ", err)
else:
    print("Reading file succesfull")
```

**When to use it:**
When you want to read the content of a registered file as long as it wasn't changed unexpectedly.

### Change File Path method
**What it does:**
Changes the file location of a registered file to the new directory and returns an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how changing the file path failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to move now
- ```Directory``` is the new directory the file should be saved into

```gdscript
var file_name := "save"
var directory := "user://"
var err := DataManager.change_file_path(file_name, directory)
if (err != OK):
    print("Moving file failed with error id: ", err)
else:
    print("Moving file succesfull")
```

**When to use it:**
When you want to move the file location of a registered file.

### Update File Content method
**What it does:**
Updates the content of a registered file, completly replacing the current content and returns an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how replacing the file content failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to rewrite the content of
- ```Content``` is the new content that should replace the current content

```gdscript
var file_name := "save"
var content := "Example"
var err := DataManager.update_file_content(file_name, content)
if (err != OK):
    print("Updating file content failed with error id: ", err)
else:
    print("Updating file content succesfull")
```

**When to use it:**
When you want to replace the current content of a registered file with the newly given content, so that the old content is overwritten.

### Append File Content method
**What it does:**
Appends the content to a registered file, keeping the current content and returns an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how appending to the file content failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to rewrite the content of
- ```Content``` is the new content that should replace the current content

```gdscript
var file_name := "save"
var content := "Example"
var err := DataManager.append_file_content(file_name, content)
if (err != OK):
    print("Appending file content failed with error id: ", err)
else:
    print("Appending file content succesfull")
```

**When to use it:**
When you want to append the given content the current content of a registered file, so that the old content still stays in the file.

### Compare Hash method
**What it does:**
Compares the current hash with the last expected hash and returns an instance of the ValueError class, where the value (gettable with ```get_value()```), is the bool deciding wheter the given has been changed  or not and where the error (gettable with ```get_error()```) is an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter the file has been changed or not.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to check the hash now

```gdscript
var file_name := "save"
var result := DataManager.compare_hash(file_name)
var same_hash = result.get_value()
var err := result.get_error()
if (err != OK):
    print("Comparing file hash failed with error id: ", err)
else:
    if (same_hash):
        print("Hash is as expected, file has not been changed outside of the environment")
    else:
        print("Hash is different than expected, accessing might not be save anymore")
```

**When to use it:**
When you want to check if the file was changed outisde of the environment by for example the user editing the file from the file explorer.

### Delete File method
**What it does:**
Deletes a registered file and unregisters it and returns an integer representing the GlobalScope Error Enum (see [Possible Errors](#possible-errors)), showing wheter and how deleting the file failed.

**How to call it:**
- ```FileName``` is the name without extension we have given the registered file and want to delete now

```gdscript
var file_name := "save"
var err := DataManager.delete_file(file_name)
if (err != OK):
    print("Deleting file failed with error id: ", err)
else:
    print("Deleting file succesfull")
```

**When to use it:**
When you want to delete a file and unregister it from the environment, if it is for example no longer needed.
