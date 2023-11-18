/// @desc Airkiver Example

// Create a new Airkiver Object
airkiver = new Airkiver();

var timer = get_timer();
airkiver.load("archive.ft");
show_debug_message($"'archive.ft' took {(get_timer() - timer) / 1000}ms to load");
timer = get_timer();
airkiver.build_directory_tree();
show_debug_message($"build_directory_tree() took {(get_timer() - timer) / 1000}ms");

show_debug_message($"file count {array_length(variable_struct_get_names(airkiver.filetable))}");

// Load Airkiver File
timer = get_timer();
var text = airkiver.retrieve_text("hello.txt", false);
show_debug_message($"retrieve_text() took {(get_timer() - timer) / 1000}ms");

// Load Airkiver File
timer = get_timer();
var buffer = buffer_load("hello.txt");
var text2 = buffer_read(buffer, buffer_text);
show_debug_message($"buffer_load() took {(get_timer() - timer) / 1000}ms");
show_debug_message(text);

game_end();