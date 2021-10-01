extends Node

onready var _compression_mode := $CompressionModeInput/OptionButton
onready var _encryption := $EncryptionInput/CheckButton
onready var _file_name := $FileNameInput/TextEdit
onready var _file_content := $FileContentInput/TextEdit

func _ready() -> void:
    _compression_mode.add_item("None", 4)
    _compression_mode.add_item("Fastlz", File.COMPRESSION_FASTLZ)
    _compression_mode.add_item("Deflate", File.COMPRESSION_DEFLATE)
    _compression_mode.add_item("Zstandard", File.COMPRESSION_ZSTD)
    _compression_mode.add_item("Gzip", File.COMPRESSION_GZIP)

func _on_Button_pressed() -> void:
    var splits = _file_name.text.split(".")
    var file_name = splits[0]
    var file_extension = "." + splits[-1]
    var content = _file_content.text
    var compression = _compression_mode.get_selected_id()
    var encryption = _encryption.is_pressed()
    if (compression == 4):
        compression = -1
    DataManager.create_new_file(file_name, content, "C:/Users/Deutsch/Downloads", file_extension, encryption, false, compression)
