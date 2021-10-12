extends Node

onready var _compression_mode := $Input/CompressionModeInput/OptionButton
onready var _encryption := $Input/EncryptionInput/CheckButton
onready var _hashing := $Input/HashingInput/CheckButton
onready var _file_name := $Input/FileNameInput/TextEdit
onready var _file_content := $Input/FileContentInput/TextEdit
onready var _file_path := $Input/FilePathInput/TextEdit
onready var _output := $Output/TextEdit

func _ready() -> void:
    _compression_mode.add_item("None", 4)
    _compression_mode.add_item("Fastlz", File.COMPRESSION_FASTLZ)
    _compression_mode.add_item("Deflate", File.COMPRESSION_DEFLATE)
    _compression_mode.add_item("Zstandard", File.COMPRESSION_ZSTD)
    _compression_mode.add_item("Gzip", File.COMPRESSION_GZIP)

func _on_CreateFile_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var file_extension = "." + splits[-1]
    var compression = _compression_mode.get_selected_id()
    var encryption = _encryption.is_pressed()
    var hashing = _hashing.is_pressed()
    if (compression == 4):
        compression = -1
    var err := DataManager.create_new_file(file_name, _file_content.text, _file_path.text, file_extension, encryption, hashing, compression)
    if (err != OK):
        message = "Creating file failed with error message: " + _error_to_message(err)
    else:
        message = "Creating file succesfull."
    _output.text = message

func _on_ReadFile_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var result := DataManager.read_from_file(file_name)
    _file_content.text = result.get_value()
    var err = result.get_error()
    if (err != OK):
        message = "Reading file failed with error message: " + _error_to_message(err)
    else:
        message = "Reading file succesfull."
    _output.text = message

func _on_DeleteFile_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var err := DataManager.delete_file(file_name)
    if (err != OK):
        message = "Deleting file failed with error message: " + _error_to_message(err)
    else:
        message = "Deleting file succesfull."
    _output.text = message

func _on_ChangeFilePath_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var err := DataManager.change_file_path(file_name, _file_path.text)
    if (err != OK):
        message = "Moving file failed with error message: " + _error_to_message(err)
    else:
        message = "Moving file succesfull."
    _output.text = message

func _on_UpdateFile_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var err := DataManager.update_file_content(file_name, _file_content.text)
    if (err != OK):
        message = "Updating file content failed with error message: " + _error_to_message(err)
    else:
        message = "Updating file content succesfull."
    _output.text = message

func _on_AppendFile_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var err := DataManager.append_file_content(file_name, _file_content.text)
    if (err != OK):
        message = "Appending file content failed with error message: " +_error_to_message(err)
    else:
        message = "Appending file content succesfull."
    _output.text = message

func _on_CompareHash_pressed():
    var message := ""
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var result := DataManager.compare_hash(file_name)
    var same_hash = result.get_value()
    var err = result.get_error()
    if (err != OK):
        message = "Comparing file hash failed with error message: " +_error_to_message(err)
    else:
        if (same_hash):
            message = "Hash is as expected, file has not been changed outside of the environment."
        else:
            message = "Hash is different than expected, accessing might not be save anymore."
    _output.text = message

func _error_to_message(err : int) -> String:
    var message := ""
    match(err):
        ERR_FILE_BAD_PATH:
            message = "Given path does not exist."
        ERR_INVALID_PARAMETER:
            message = "Can not both encrypt and compress a file."
        ERR_FILE_CORRUPT:
            message = "File has been changed outside of the environment, accessing might not be save anymore."
        ERR_FILE_MISSING_DEPENDENCIES:
            message = "Tried to compare hash, but hasing has not been enabled for the given file."
        ERR_FILE_UNRECOGNIZED:
            message = "File has not been registered with the create file function yet."
        ERR_ALREADY_EXISTS:
            message = "A file already exists at the same path, choose a different name or directory."
        ERR_DOES_NOT_EXIST:
            message = "There is no file with the given name in the given directory, ensure it wasn't moved or deleted."
        ERR_CANT_RESOLVE:
            message = "Could not delete file as the entry does not exists in the dictionary anymore."
        _:
            message = "Opening file failed."
    return message
