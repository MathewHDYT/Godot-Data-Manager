extends Node

onready var _compression_mode := $Input/CompressionModeInput/OptionButton
onready var _encryption := $Input/EncryptionInput/CheckButton
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
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var file_extension = "." + splits[-1]
    var compression = _compression_mode.get_selected_id()
    var encryption = _encryption.is_pressed()
    if (compression == 4):
        compression = -1
    if (!DataManager.create_new_file(file_name, _file_content.text, _file_path.text, file_extension, encryption, false, compression)):
        _output.text = "Creating file failed"

func _on_ReadFile_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    _file_content.text = DataManager.read_from_file(file_name)

func _on_DeleteFile_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    if (!DataManager.delete_file(file_name)):
        _output.text = "Deleting file failed"

func _on_ChangeFilePath_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    if (!DataManager.change_file_path(file_name, _file_path.text)):
        _output.text = "Changin file path failed"

func _on_UpdateFile_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    if (!DataManager.update_file_content(file_name, _file_content.text)):
        _output.text = "Updating file content failed"

func _on_AppendFile_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    if (!DataManager.append_file_content(file_name, _file_content.text)):
        _output.text = "Appending file content failed"

func _on_CompareHash_pressed():
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    if (!DataManager.compare_hash(file_name)):
        _output.text = "Hash is different than expected or hashing is not enabled"
