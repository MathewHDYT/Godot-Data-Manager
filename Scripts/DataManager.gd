extends Node

func _ready() -> void:
    if (!_check_file(FILENAME_FILES, true)):
        _update_file_names()
    else:
        # If it is we can just load all it's contents
        # and save them into our dictionary.
        _load_file_names()

# Creates and registers a new file with the given properties.
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
func update_file_content(file_name : String, content : String) -> bool:
    var success := false
    var file_data := _get_file_data(file_name)
    if (file_data == null):
        return success
    success = _detect_write_mode(file_data, content, File.WRITE)
    return success

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

class FileData:
    var _file_path := ""
    var _file_hash := ""
    var _file_key := false
    var _file_compression := -1

    func get_file_path() -> String:
        return _file_path

    func set_file_path(file_path : String) -> void:
        _file_path = file_path

    func get_file_hash() -> String:
        return _file_hash

    func set_file_hash(file_hash : String) -> void:
        _file_hash = file_hash

    func get_file_key() -> bool:
        return _file_key

    func set_file_key(file_key : bool) -> void:
        _file_key = file_key

    func get_file_compression() -> int:
        return _file_compression

    func set_file_compression(file_compression : bool) -> void:
        _file_compression = file_compression

    func _init(file_path : String, file_hash : String, file_key : bool, file_compression : int):
        _file_path = file_path
        _file_hash = file_hash
        _file_key = file_key
        _file_compression = file_compression

func _check_file(file_path : String, file_exists := false) -> bool:
    var result := _get_file_state(file_path, file_exists)
    var message = result[0]
    var success = result[1]
    if (message != ""):
        printerr(message)
    return success;

func _get_file_data(file_name : String) -> FileData:
    var file_data = _file_dictionary.get(file_name)
    # Check if the key existed and we succesfully got the value.
    if (file_data == null):
        printerr("Given file name: " + file_name + " is not registered")
    return file_data

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

func _add_to_dictionary(file_name : String, file_data : FileData) -> void:
    # Add the data to the dictionary.
    _file_dictionary[file_name] = file_data
    _update_file_names()

func _remove_from_dictionary(file_name : String) -> bool:
    # Remove the data from the dictionary.
    var success := _file_dictionary.erase(file_name)
    _update_file_names()
    return success

func _update_file_names() -> void:
    var file = File.new()
    file.open(FILENAME_FILES, File.WRITE)
    # Convert the whole dictionary to a json string
    var json := JSON.print(_file_dictionary)
    # and store it into our save file.
    file.store_string(json)
    file.close()

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

func _get_file_hash(file_path : String) -> String:
    var file = File.new()
    var file_hash = file.get_sha256(file_path)
    file.close()
    return file_hash

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

func _read_from_file(file_path : String, file_mode : int) -> String:
    var file = File.new()
    var err = file.open(file_path, file_mode)
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content

func _read_from_compressed_file(file_data : FileData, file_mode : int) -> String:
    var file = File.new()
    var err = file.open_compressed(file_data.get_file_path(), file_mode, file_data.get_file_compression())
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content

func _read_from_encrypted_file(file_path : String, file_mode : int) -> String:
    var file = File.new()
    var err = file.open_encrypted_with_pass(file_path, file_mode, FILE_KEY)
    var content = ""
    if (err != OK):
        return content
    content = file.get_as_text()
    file.close()
    return content
