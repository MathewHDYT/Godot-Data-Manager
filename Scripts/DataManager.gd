extends Node

# Creates and registers a new file with the given properties, writes the given text to it
# and returns an integer representing the GlobalScope Error Enum, 
# showing wheter and how creating the file failed.
# file_name (String): Name the given file should have (is used as the ID so make sure it's unique)
# content (String): Inital data that should be saved into the file.
# directory_path (String): Directory the file shoukd be saved into.
# file_ending (String): Ending the given file should have.
# encryption (bool): Wether the given file should be encrypted.
# hashing (bool): Wheter the given file should be checked for unexpected changes before using it.
# compression (int or File.CompressionMode): Wheter and with which compression algorithm the given file should be compressed.
func create_new_file(file_name : String, content := "", directory_path := "user://", file_ending := ".txt", encryption := false, hashing := false, compression := -1) -> int:
    var err := OK
    # Check if the directory path ends with a delimeter if it doesn't add one.
    if directory_path[-1] != '/':
        directory_path += '/'
    # Get the file_path from the given values and save it into a FileData object.
    var file_path := directory_path + file_name + file_ending
    var dir := Directory.new()
    if (!dir.dir_exists(directory_path)):
        err = ERR_FILE_BAD_PATH
        return err
    var file_hash := ""
    # Add data of the newly created file to a file data instance.
    var file_data := FileData.new(file_path, file_hash, encryption, compression)
    err = _check_file_not_exists(file_path).get_error()
    if (err != OK):
        return err
    if (encryption && compression >= 0):
        err = ERR_INVALID_PARAMETER
        return err
    err = _detect_write_mode(file_data, content, File.WRITE)
    # Check if the file should be hashed.
    if (hashing):
        file_data.set_file_hash(_get_file_hash(file_path))
    # Add file data instance to the dictionary, after the hash has been updated if needed.
    _add_to_dictionary(file_name, file_data)
    return err

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the text from the given file, that is an empty string,
# when the file is not yet registered or when the hash is not as expected,
# if hashing is enabled for the given file
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter and how reading the file failed.
# file_name (String): Name of the given file that should be read from.
func read_from_file(file_name : String) -> ValueError:
    var value_error := ValueError.new("", OK)
    value_error.set_data(_get_file_data(file_name))
    if (value_error.get_error() != OK):
        return value_error
    # Check if hashing is enabled and we therefore saved the latest hash in file_data.
    # Check if the hash is still the same or if it was changed.
    if (value_error.get_value().get_file_hash() != "" && !compare_hash(file_name).get_value()):
        # If it was don't read our given content from the file.
        value_error.set_error(ERR_FILE_CORRUPT)
        return value_error
    # Check if the file should be only encrypted.
    if (value_error.get_value().get_file_key()):
        value_error.set_data(_read_from_encrypted_file(value_error.get_value().get_file_path(), File.READ))
    # Check if the file should be only compressed.
    elif (value_error.get_value().get_file_compression() >= 0):
        value_error.set_data(_read_from_compressed_file(value_error.get_value(), File.READ))
    else:
        value_error.set_data(_read_from_file(value_error.get_value().get_file_path(), File.READ))
    return value_error

# Changes the file location of the given file to the new directory
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how changing the file path failed.
# file_name (String): Name of the given file that should be moved.
# directory_path (String): New directory the given file should be moved too.
func change_file_path(file_name : String, directory_path : String) -> int:
    var err := OK
    # Check if the directory path ends with a delimeter if it doesn't add one.
    if directory_path[-1] != '/':
        directory_path += '/'
    var result := _get_file_data(file_name)
    var file_data = result.get_value()
    err = result.get_error()
    if (err != OK):
        return err
    # Check if the given path exists.
    var dir := Directory.new()
    if (!dir.dir_exists(directory_path)):
        err = ERR_FILE_BAD_PATH
        return err
    # Split the full file_path into the seperate directories, subdirectories and the filename with extnesion,
    # then get the last element of that array, which is the filename with extension.
    var name = file_data.get_file_path().split("/")[-1]
    var file_path = directory_path + name
    # Check if the file exists already at the given path.
    err = _check_file_not_exists(file_path).get_error()
    if (err != OK):
        return err
    # Move the file to its new location and adjust the file_path to the new value.
    err = dir.rename(file_data.get_file_path(), file_path)
    if (err != OK):
        return err
    file_data.set_file_path(file_path)
    return err

# Updates the content of the given file, completly replacing the current content
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how replacing the file content failed.
# file_name (String): Name of the given file that should have its content replaced.
# content (String): Data that should be saved into the file.
func update_file_content(file_name : String, content : String) -> int:
    var err := OK
    var result := _get_file_data(file_name)
    var file_data = result.get_value()
    err = result.get_error()
    if (err != OK):
        return err
    err = _detect_write_mode(file_data, content, File.WRITE)
    return err

# Appends the content to the given file, keeping the current content
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how appending to the file content failed.
# file_name (String): Name of the given file that should have the content appended.
# content (String): Data that should be appended to the file.
func append_file_content(file_name : String, content : String) -> int:
    var err := OK
    var result := _get_file_data(file_name)
    var file_data = result.get_value()
    err = result.get_error()
    if (err != OK):
        return err
    # Check if hashing is enabled and we therefore saved the latest hash in file_data.
    # Check if the hash is still the same or if it was changed.
    if (file_data.get_file_hash() != "" && !compare_hash(file_name)):
        # If it was don't append our given content to the file.
        err = ERR_FILE_CORRUPT
        return err
    err = _detect_write_mode(file_data, content, File.READ_WRITE)
    return err

# Compares the current hash with the last expected hash
# and returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the bool deciding wheter the given has been changed  or not
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter the file has been changed or not.
# file_name (String): Name of the given file that should have its hash checked.
func compare_hash(file_name : String) -> ValueError:
    var value_error := ValueError.new(false, OK)
    value_error.set_data(_get_file_data(file_name))
    if (value_error.get_error() != OK):
        return value_error
    elif (value_error.get_value().get_file_hash() == ""):
        value_error.set_error(ERR_FILE_MISSING_DEPENDENCIES)
        return value_error
    var current_hash := _get_file_hash(value_error.get_value().get_file_path())
    value_error.set_value(current_hash == value_error.get_value().get_file_hash())
    return value_error

# Deletes the given file and unregisters it
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how deleting the file failed.
# file_name (String): Name of the given file that should be deleted.
func delete_file(file_name : String) -> int:
    var err := OK
    var result := _get_file_data(file_name)
    var file_data = result.get_value()
    err = result.get_error()
    if (err != OK):
        return err
    #value_error.set_error(_check_file_exists(value_error.get_value().get_file_path())
    if (err != OK):
        return err
    var dir := Directory.new()
    err = dir.remove(file_data.get_file_path())
    if (err != OK):
        return err
    err = dir.remove(FILEDATA_DICTIONARY + file_name + FILEDATA_FILE)
    if (err != OK):
        return err
    err = _remove_from_dictionary(file_name)
    _update_file_names()
    return err

#-----------------------------------------------------------------------------
# Private
#-----------------------------------------------------------------------------

const DICTIONARY_KEY_FILE := "user://file_name.save"
const FILEDATA_DICTIONARY := "user://"
const FILEDATA_FILE := "_file_data.save"
const FILE_KEY := "ja9tEHvXzvJcwDOiwQoI"

var _file_dictionary  := Dictionary()

# Contains the return value of a given function as well as the error the function returned
class ValueError:
    var _value
    var _err := OK

    # Getter for the value.
    func get_value():
        return _value

    # Setter for the value.
    func set_value(value) -> void:
        _value = value

    # Getter for the error.
    func get_error() -> int:
        return _err

    # Setter for the error.
    func set_error(err : int) -> void:
        _err = err

    func set_data(value_error : ValueError) -> void:
        _value = value_error.get_value()
        _err = value_error.get_error()

    # Constructor for the ValueError class.
    func _init(value, err : int) -> void:
        _value = value
        _err = err

# Contains information needed to reload and reaccess the file after the game session has been reset.
class FileData:
    var _file_path := ""
    var _file_hash := ""
    var _file_key := false
    var _file_compression := -1

    # Getter for the file path.
    func get_file_path() -> String:
        return _file_path

    # Setter for the file path.
    func set_file_path(file_path : String) -> void:
        _file_path = file_path

    # Getter for the file hash.
    func get_file_hash() -> String:
        return _file_hash

    # Setter for the file hash.
    func set_file_hash(file_hash : String) -> void:
        _file_hash = file_hash

    # Getter for the file key.
    func get_file_key() -> bool:
        return _file_key

    # Setter for the file key.
    func set_file_key(file_key : bool) -> void:
        _file_key = file_key

    # Getter for the file compression.
    func get_file_compression() -> int:
        return _file_compression

    # Setter for the file compression.
    func set_file_compression(file_compression : bool) -> void:
        _file_compression = file_compression

    # Constructor for the FileData class.
    func _init(file_path : String, file_hash : String, file_key : bool, file_compression : int) -> void:
        _file_path = file_path
        _file_hash = file_hash
        _file_key = file_key
        _file_compression = file_compression

# Called when the game is started.
func _ready() -> void:
    # Check if there has been a previous game session, with saved game files.
    if (!_check_file_exists(DICTIONARY_KEY_FILE).get_value()):
        # If there wasn't we need to create the file initially.
        _update_file_names()
    else:
        # If there was we can just load all the saved game files contents
        # into our dictionary.
        _load_file_names()

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the FileData object from the given file name out of our dictionary
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter and how getting the FileData object failed.
func _get_file_data(file_name : String) -> ValueError:
    var value_error := ValueError.new(null, OK)
    value_error.set_value(_file_dictionary.get(file_name))
    # Check if the key existed and we succesfully got the value.
    if (value_error.get_value() == null || !value_error.get_value() is FileData):
        value_error.set_error(ERR_FILE_UNRECOGNIZED)
    return value_error

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the bool deciding wheter a file actually exists at the given location
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter the file exists or not at the given location.
func _check_file_exists(file_path : String) -> ValueError:
    var value_error := ValueError.new(false, OK)
    var file := File.new()
    value_error.set_value(file.file_exists(file_path))
    file.close()
    # Check if the file doesn't exist
    if (!value_error.get_value()):
        value_error.set_error(ERR_DOES_NOT_EXIST)
    return value_error

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the bool deciding wheter a file doesn't already exists at the given location
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter the file doesn't already exist at the given location.
func _check_file_not_exists(file_path : String) -> ValueError:
    var value_error := ValueError.new(false, OK)
    var file := File.new()
    value_error.set_value(file.file_exists(file_path))
    file.close()
    # Check if the file doesn't exist
    if (value_error.get_value()):
        value_error.set_error(ERR_ALREADY_EXISTS)
    return value_error

# Add the given FileData to the dictionary, where the value is the FileData and the key is our file name
func _add_to_dictionary(file_name : String, file_data : FileData) -> void:
    # Add the data to the dictionary.
    _file_dictionary[file_name] = file_data
    _update_file_names()

# Removes the entry from our dictonary with the given key
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter deleting the entry from the dictionary failed or not,
func _remove_from_dictionary(file_name : String) -> int:
    var err := OK
    # Remove the data from the dictionary.
    var success := _file_dictionary.erase(file_name)
    if (not success):
        err = ERR_CANT_RESOLVE
        return err
    _update_file_names()
    return err

# Updates the save file that contains our dictionary data.
func _update_file_names() -> void:
    var file = File.new()
    file.open(DICTIONARY_KEY_FILE, File.WRITE)
    # Convert the whole dictionary to a json string.
    var json := JSON.print(_file_dictionary.keys())
    # and store it into our save file.
    file.store_string(json)
    file.close()
    # Update or save the file data file for each file_data instance.
    for key in _file_dictionary:
        var save_path := FILEDATA_DICTIONARY + (key as String) + FILEDATA_FILE
        file.open(save_path, File.WRITE)
        # Get the needed data from the file data object instance.
        var file_data := _file_dictionary[key] as FileData
        var file_path := file_data.get_file_path()
        var file_hash := file_data.get_file_hash()
        var file_key := file_data.get_file_key()
        var file_compression := file_data.get_file_compression()
        # Create an array from that data and serialize it as a json.
        var data_array = [file_path, file_hash, file_key, file_compression]
        json = JSON.print(data_array)
        file.store_string(json)
        file.close()

# Loads the save file dave and saves it into the dictionary.
# This is needed to reconstruct the dictionary on game start,
# so that the files are still accesible even if we restart the game.
func _load_file_names() -> void:
    var file = File.new()
    file.open(DICTIONARY_KEY_FILE, File.READ)
    var json = file.get_as_text()
    file.close()
    var parse_result := JSON.parse(json)
    if parse_result.error != OK:
        printerr(parse_result.error_string)
        return
    var dict_keys = parse_result.result
    # Load the file_data file for each file_data instance.
    for key in dict_keys:
        var save_path := FILEDATA_DICTIONARY + (key as String) + FILEDATA_FILE
        file.open(save_path, File.READ)
        json = file.get_as_text()
        file.close()
        parse_result = JSON.parse(json)
        if parse_result.error != OK:
            printerr(parse_result.error_string)
            return
        var data_array = parse_result.result
        # Get the needed data to create the file data object instance, from the data array object.
        var file_path = data_array[0]
        var file_hash = data_array[1]
        var file_key = data_array[2]
        var file_compression = data_array[3]
        var file_data := FileData.new(file_path, file_hash, file_key, file_compression)
        _add_to_dictionary(key, file_data)

# Returns the file hash from the given file at the given location.
func _get_file_hash(file_path : String) -> String:
    var file = File.new()
    var file_hash = file.get_sha256(file_path)
    file.close()
    return file_hash

# Detects in which mode the file should be edited in
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how writing to the file failed.
func _detect_write_mode(file_data : FileData, content : String, file_mode : int) -> int:
    var err := OK
    # Check if encryption is enabled.
    if (file_data.get_file_key()):
        err = _write_to_encrypted_file(content, file_data.get_file_path(), file_mode)
    elif (file_data.get_file_compression() >= 0):
        err = _write_to_compressed_file(content, file_data, file_mode);
    else:
        err = _write_to_file(content, file_data.get_file_path(), file_mode)
    # Check if hashing is enabled and we therefore saved the latest hash in file_data.
    if (file_data.get_file_hash() != ""):
        file_data.set_file_hash(_get_file_hash(file_data.get_file_path()))
    return err

# Simply writes the given content to the given file
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how writing to the file failed.
func _write_to_file(content : String, file_path : String, file_mode : int) -> int:
    var file = File.new()
    var err = file.open(file_path, file_mode)
    if (err != OK):
        return err
    # If the file mode is append we want to seek the end of the file,
    # so we actually don't completly or partially overwrite the old content with the new one.
    if (file_mode == File.READ_WRITE):
        file.seek_end()
    file.store_string(content)
    file.close()
    return err

# Writes the given content to the given file and compressed it with the given compression algorithm
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how writing to the file failed.
func _write_to_compressed_file(content : String, file_data : FileData, file_mode : int) -> int:
    var file = File.new()
    var err = file.open_compressed(file_data.get_file_path(), file_mode, file_data.get_file_compression())
    if (err != OK):
        return err
    # If the file mode is append we want to seek the end of the file,
    # so we actually don't completly or partially overwrite the old content with the new one.
    if (file_mode == File.READ_WRITE):
        file.seek_end()
    file.store_string(content)
    file.close()
    return err

# Writes the given content to the given file and encrypts it
# and returns an integer representing the GlobalScope Error Enum,
# showing wheter and how writing to the file failed.
func _write_to_encrypted_file(content : String, file_path : String, file_mode : int) -> int:
    var file = File.new()
    var err = file.open_encrypted_with_pass(file_path, file_mode, FILE_KEY)
    if (err != OK):
        return err
    # If the file mode is append we want to seek the end of the file,
    # so we actually don't completly or partially overwrite the old content with the new one.
    if (file_mode == File.READ_WRITE):
        file.seek_end()
    file.store_string(content)
    file.close()
    return err

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the content from the given file
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter and how reading from the file failed.
func _read_from_file(file_path : String, file_mode : int) -> ValueError:
    var value_error := ValueError.new("", OK)
    var file = File.new()
    value_error.set_error(file.open(file_path, file_mode))
    if (value_error.get_error() != OK):
        return value_error
    value_error.set_value(file.get_as_text())
    file.close()
    return value_error

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the decompressed content from the given file
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter and how reading from the compressed file failed.
func _read_from_compressed_file(file_data : FileData, file_mode : int) -> ValueError:
    var value_error := ValueError.new("", OK)
    var file = File.new()
    value_error.set_error(file.open_compressed(file_data.get_file_path(), file_mode, file_data.get_file_compression()))
    if (value_error.get_error() != OK):
        return value_error
    value_error.set_value(file.get_as_text())
    file.close()
    return value_error

# Returns an instance of the ValueError class, where the value (gettable with get_value()),
# is the encrypted content from the given file
# and where the error (gettable with get_error()) is an integer representing the GlobalScope Error Enum,
# showing wheter and how reading from the encrypted file failed.
func _read_from_encrypted_file(file_path : String, file_mode : int) -> ValueError:
    var value_error := ValueError.new("", OK)
    var file = File.new()
    value_error.set_error(file.open_encrypted_with_pass(file_path, file_mode, FILE_KEY))
    if (value_error.get_error() != OK):
        return value_error
    value_error.set_value(file.get_as_text())
    file.close()
    return value_error
