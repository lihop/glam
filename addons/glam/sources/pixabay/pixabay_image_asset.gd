# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../../assets/image_asset.gd"

const CacheableHTTPRequest = preload("../../util/cacheable_http_request.gd")

var image_urls := {}


func _init(pixabay_source: Node):
	source = pixabay_source


#func download(node: Node = source):
#	# TODO: Configure resolution
#	var url: String = image_urls["large"]
#	# Use preview url for pretty filename.
#	var basename = image_urls["small"].get_file()
#	var filename := "%s/%s" % [get_directory(), basename]
#	Directory.new().make_dir_recursive(filename.get_base_dir())
#
#	var http_request = CacheableHTTPRequest.new()
#	node.add_child(http_request)
#	http_request.download_file = filename
#	http_request.connect("request_completed", self, "_on_downloaded", [filename, http_request])
#	http_request.request(url)


func _on_downloaded(result, response_code, _headers, _body, filename, http_request):
	http_request.queue_free()

	if result != OK or response_code != 200:
		push_error("Error")

#	var imports: Array = yield(import_files(), "completed")
#	for import in imports:
#		print(import.name)
#		print(import.resource)

#	print("Adoing!")
#	yield(source.rescan_filesystem(), "completed")
#	create_license_file("%s.license" % filename, authors, licenses)
#	#create_placeholder()
#	yield(source.get_tree(), "idle_frame")
#	#var res: StreamTexture = load(get_filepath())
#	#var thing = load(filename)
#
#	yield(source.get_tree().create_timer(5), "timeout")
#	var thing: StreamTexture = load(filename)
#	var placeholder = load(get_filepath())
#	placeholder.load_path = thing.load_path
#	ResourceSaver.save(get_filepath(), placeholder)
#	print("Done so!")
