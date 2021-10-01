extends Node

# Creates and registers a new file with the given properties abd writes the given text to it.
# file_name (String): Name the given file should have (is used as the ID so make sure it's unique)
# content (String): Inital data that should be saved into the file.
# directory_path (String): Directory the file shoukd be saved into.
# file_ending (String): Ending the given file should have.
# encryption (bool): Wether the given file should be encrypted.
# hashing (bool): Wheter the given file should be checked for unexpected changes before using it.
# compression (int or File.CompressionMode): Wheter and with which compression algorithm the given file should be compressed.
func create_new_file(file_name : String, content := "", directory_path := "user://", file_ending := ".txt", encryption := false, hashing := false, compression := -1) -> bool:
    var success := false
    # Check if the directory path ends with a delimeter if it doesn't add one.
    if directory_path[-1] != '/':
        directory_path += '/'
    # Get the file_path from the given values and save it into a FileData object.
    var file_path := directory_path + file_name + file_ending
    var file_hash := ""
    # Add data of the newly created file to the dictionary.
    var file_data := FileData.new(file_path, file_hash, encryption, compression);
    _add_to_dictionary(file_name, file_data)
    if (_check_file(file_path)):
        return success
    if (encryption && compression >= 0):
        printerr("File can't be both encrypted and compressed")
        return success
    success = _detect_write_mode(file_data, content, File.WRITE)
    # Check if the file should be hashed.
    if (hashing):
        file_data.set_file_hash(_get_file_hash(file_path))
    return success

# Returns the text from the given file. Returns an empty string,
# when the file is nto yet registered or when the hash is not as expected,
# if hashing is enabled for the given file.
# file_name (String): Name of the given file that should be read from.
func read_from_file(file_name : String) -> String:
    var content = ""
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return content
    # Check if hashing is enabled and we therefore saved the latest hash in file_data.
    # Check if the hash is still the same or if it was changed.
    if (file_data.get_file_hash() != "" && !compare_hash(file_name)):
        # If it was don't read our given content from the file.
        return content
    # Check if the file should be only encrypted.
    if (file_data.get_file_encryption()):
        content = _read_from_encrypted_file(file_data.get_file_path(), File.READ)
    # Check if the file should be only compressed.
    elif (file_data.get_file_compression() >= 0):
        content = _read_from_compressed_file(file_data, File.READ)
    else:
        content = _read_from_file(file_data.get_file_path(), File.READ)
    return content

# Changes the file location of the given file to the new directory and
# returns true if it succeeded.
# file_name (String): Name of the given file that should be moved.
# directory (String): New directory the given file should be moved too.
func change_file_path(file_name : String, directory : String) -> bool:
    var success := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return success
    # Check if the given path exists.
    var dir := Directory.new()
    if (!dir.dir_exists(directory)):
        printerr("Given directory: " + directory + " does not exist");
        return success
    # Split the full file_path into the seperate directories, subdirectories and the filename with extnesion,
    # then get the last element of that array, which is the filename with extension.
    var name := file_data.get_file_path().split("/")[-1]
    var file_path := directory + name
    # Check if the file exists already at the given path.
    if (_check_file(file_path)):
        return success
    # Move the file to its new location and adjust the file_path to the new value.
    var err := dir.rename(file_data.get_file_path(), file_path)
    success = err == OK
    file_data.set_file_path(file_path)
    return success

# Updates the content of the given file, completly replacing the current content and
# returning true if succesful and false if not.
# file_name (String): Name of the given file that should have its content replaced.
# content (String): Data that should be saved into the file.
func update_file_content(file_name : String, content : String) -> bool:
    var success := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return success
    success = _detect_write_mode(file_data, content, File.WRITE)
    return success

# Appends the content to the given file, keeping the current content and
# returning true if succesful and false if not. Will not be executed and return false,
# if hashing is enabled and the hash of the file has changed still we last changed it ourselves.
# file_name (String): Name of the given file that should have the content appended.
# content (String): Data that should be appended to the file.
func append_file_content(file_name : String, content : String) -> bool:
    var success := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return success
    # Check if hashing is enabled and we therefore saved the latest hash in file_data.
    # Check if the hash is still the same or if it was changed.
    if (file_data.get_file_hash() != "" && !compare_hash(file_name)):
        # If it was don't append our given content to the file.
        return success
    success = _detect_write_mode(file_data, content, File.READ_WRITE)
    return success

# Compares the current hash with the last expected hash
# and returns true if it is the same and false if it isn't.
# file_name (String): Name of the given file that should have its hash checked.
func check_file_hash(file_name : String) -> bool:
    var result := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return result
	elif (file_data.get_file_hash() == ""):
		return result
    var current_hash := _get_file_hash(file_data.get_file_path())
    result = current_hash == file_data.get_file_hash()
    return result

# Deletes the given file and unregisters it.
# file_name (String): Name of the given file that should be deleted.
func delete_file(file_name : String) -> bool:
    var success := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return success
    elif (!_check_file(file_data.get_file_path(), true)):
        return success
    var dir := Directory.new()
    var err := dir.remove(file_data.get_file_path())
    if err != OK:
        return success
    success = _remove_from_dictionary(file_name)
    _update_file_names()
    return success

#-----------------------------------------------------------------------------
# Private
#-----------------------------------------------------------------------------

const FILENAME_FILES := "user://file_name.save"
const FILE_KEY := "ja9tEHvXzvJcwDOiwQoI"

var _file_dictionary  := Dictionary()

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
    func _init(file_path : String, file_hash : String, file_key : bool, file_compression : int):
        _file_path = file_path
        _file_hash = file_hash
        _file_key = file_key
        _file_compression = file_compression

# Called when the game is started.
func _ready() -> void:
    # Check if there has been a previous game session, with saved game files.
    if (!_check_file(FILENAME_FILES, true)):
        # If there wasn't we need to create the file initially.
        _update_file_names()
    else:
        # If there was we can just load all the saved game files contents
        # into our dictionary.
        _load_file_names()

# Checks if the file at the given location exists and returns a message,
# if the expected result is different then the actual result.
func _check_file(file_path : String, file_exists := false) -> bool:
    var result := _get_file_state(file_path, file_exists)
    var message = result[0]
    var success = result[1]
    if (message != ""):
        printerr(message)
    return success;

# Gets the FileData object from the given file name otu of our dictionary.
func _get_file_data(file_name : String) -> FileData:
    var file_data = _file_dictionary.get(file_name)
    # Check if the key existed and we succesfully got the value.
    if (file_data == null):
        printerr("Given file name: " + file_name + " is not registered")
    return file_data

# Gets the current state of our file consisting of it it exists and the error message,
# dpeednign on if the result is different then the expected result.
func _get_file_state(file_path : String, file_exists : bool) -> Array:
    var file := File.new()
    var result = file.file_exists(file_path)
    file.close()
    var message := ""
    if (result != file_exists):
        if (result):
            message = "There already exists a file at the given path: " + file_path
        else:
            message = "There doesn't exist a file at the given folder: " + file_path
    return [message, result]

# Add the given FileData to the dictionary, where the value is the FileData and the key is our file name
func _add_to_dictionary(file_name : String, file_data : FileData) -> void:
    # Add the data to the dictionary.
    _file_dictionary[file_name] = file_data
    _update_file_names()

# Removes the entry from our dictonary with the given key.
func _remove_from_dictionary(file_name : String) -> bool:
    # Remove the data from the dictionary.
    var success := _file_dictionary.erase(file_name)
    _update_file_names()
    return success

# Updates the save file that contains our dictionary data.
func _update_file_names() -> void:
    var file = File.new()
    file.open(FILENAME_FILES, File.WRITE)
    # Convert the whole dictionary to a json string
    var json := JSON.print(_file_dictionary)
    # and store it into our save file.
    file.store_string(json)
    file.close()

# Loads the save file dave and saves it into the dictionary.
# This is needed to reconstruct the dictionary on game start,
# so that the files are still accesible even if we restart the game.
func _load_file_names() -> void:
    var file = File.new()
    file.open(FILENAME_FILES, File.READ)
    var json = file.get_as_text()
    file.close()
    var parse_result := JSON.parse(json)
    if parse_result.error != OK:
        printerr(parse_result.error_string)
        return
    _file_dictionary = parse_result.result

# Gets the file hash from the path of the given file.
func _get_file_hash(file_path : String) -> String:
    var file = File.new()
    var file_hash = file.get_sha256(file_path)
    file.close()
    return file_hash

# Detects in which mode the file should be edited in.
func _detect_write_mode(file_data : FileData, content : String, file_mode : int) -> bool:
    var err := 0
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
    return err == OK

# Simply writes the given content to the given file.
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

# Writes the given content to the given file and compressed it with the given compression algorithm.
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

# Writes the given content to the given file and encrypts it.
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

# Simply reads the content from the given file.
func _read_from_file(file_path : String, file_mode : int) -> String:
    var file = File.new()
    var err = file.open(file_path, file_mode)
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content

# Reads the content from the given compressed file.
func _read_from_compressed_file(file_data : FileData, file_mode : int) -> String:
    var file = File.new()
    var err = file.open_compressed(file_data.get_file_path(), file_mode, file_data.get_file_compression())
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content

# Reads the content from the given encrypted file.
func _read_from_encrypted_file(file_path : String, file_mode : int) -> String:
    var file = File.new()
    var err = file.open_encrypted_with_pass(file_path, file_mode, FILE_KEY)
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content
