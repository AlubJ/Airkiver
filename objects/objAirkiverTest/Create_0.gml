/// @desc Airkiver Test
// Load Airkiver File Table
airkiver = new Airkiver("archive.ft");

// Load Airkiver File
var file = airkiver.getFile("hello.txt", true);

// Show Message
show_message(buffer_read(file, buffer_text));

// Delete Buffer
buffer_delete(file);
game_end(); 