/*
	Airkiver (c) Alun Jones
	-------------------------------------------------------------------------
	Script:			Airkiver
	Version:		v1.10
	Description:	Airkiver
	-------------------------------------------------------------------------
	History:
	 - Created 09/06/2023 by Alun Jones
	
	To Do:
	 - `retrieve_names` - multiple extensions provided as array?
*/

enum ENTRY_TYPE {
	DIRECTORY,
	FILE,
}

/// @function Airkiver([filepath], [build_directory_tree])
/// @argument filepath {String} [Filepath of the file table file]
/// @argument build_directory_tree {Bool} [Whether to build a full directory tree or not]
/// @return {Struct<Airkiver>}
/// @description Load an Airkive file and return an Airkive Struct
function Airkiver(_file = -1, _build_directory_tree = true) constructor
{
	// Settings
	defaultToFileSystem = true;
	
	// Variables
	filetable = {  };
	directory_tree = {  };
	file_count = 0;
	filepath = "";
	
	// File Table Validation and Construction
	if (file_exists(_file))
	{
		self.load(_file);
		if (_build_directory_tree) self.build_directory_tree();
	}
	else return;
	
	/// @function load(filepath)
	/// @argument filepath {String} [Filepath of the file table file]
	/// @return {Undefined}
	/// @description Load an Airkive file into the file table
	static load = function(_filepath)
	{
		// Load The File Table
		var _buffer = buffer_load(_filepath);
		
		// File Magic
		var _file_magic = buffer_read(_buffer, buffer_string);
		if (_file_magic != "Airkive") throw ("Airkiver: Unrecognised File");
		
		// File Version
		var _file_version = buffer_read(_buffer, buffer_f32);
		if (_file_version != 1.1) throw ("Airkiver: Wrong file version");
		
		// File Count
		var file_count = buffer_read(_buffer, buffer_s32);
		
		// File Loop
		repeat (file_count)
		{
			// File Offset
			var _file_offset = buffer_read(_buffer, buffer_s32);
			
			// File Size Uncompressed
			var _file_size = buffer_read(_buffer, buffer_s32);
			
			// File Size Compressed (will equal uncompressed size if file isn't compressed)
			var _file_size_compressed = buffer_read(_buffer, buffer_s32);
			
			// File Checksum (For whatever reason GameMakers CRC32 function gives a slightly different result thats fixed when read as a signed integer - 1)
			var _file_checksum = -buffer_read(_buffer, buffer_s32) - 1;
			
			// File Source
			var _file_source = buffer_read(_buffer, buffer_string);
			
			// File Name
			var _file_name = buffer_read(_buffer, buffer_string);
			
			// Add File To File Table
			filetable[$ _file_name] = {
				offset:				_file_offset,
				size:				_file_size,
				size_compressed:	_file_size_compressed,
				checksum:			_file_checksum,
				source:				_file_source,
				name:				_file_name,
			};
		}
		
		// File Path
		filepath = filename_path(_filepath);
		
		// Delete Buffer
		buffer_delete(_buffer);
	}
	
	#region Basic File Functions
	
	/// @function exists(filepath)
	/// @argument filepath {String} [Filepath of the file]
	/// @return {Bool}
	/// @description Check if a file exists in the Airkive
	static exists = function(_filepath)
	{
		return variable_struct_exists(filetable, _filepath);
	}
	
	/// @function retrieve(filepath, [validate])
	/// @argument filepath {String} [Filepath of the file]
	/// @argument validate {Bool} [Validate the file against a checksum]
	/// @return {Buffer}
	/// @description Retrieve a file from the Airkive
	static retrieve = function(_filepath, _validate = false)
	{
		// Check If File Exists
		if (!variable_struct_exists(filetable, _filepath) && (file_exists(_filepath) && defaultToFileSystem)) return buffer_load(_filepath);
		else if (!variable_struct_exists(filetable, _filepath) && !file_exists(_filepath)) return -1;
		
		// File
		var _file = filetable[$ _filepath];
		
		// Load File
		var _buffer = buffer_create(_file.size_compressed, buffer_fixed, 1);
		buffer_load_partial(_buffer, _file.source, _file.offset, _file.size_compressed, 0);
		
		// Check If File Is Compressed
		var _return_buffer = _buffer;
		if (_file.size_compressed != _file.size)
		{
			_return_buffer = buffer_decompress(_buffer);
			buffer_delete(_buffer);
		}
		
		// Validate
		if (_validate && (buffer_crc32(_return_buffer, 0, buffer_get_size(_return_buffer)) != _file.checksum))
		{
			buffer_delete(_return_buffer);
			return -1;
		}
		
		// Return Buffer
		return _return_buffer;
	}
	
	/// @function retrieve_text(filepath, [validate])
	/// @argument filepath {String} [Filepath of the file]
	/// @argument validate {Bool} [Validate the file against a checksum]
	/// @return {String}
	/// @description Retrieve text contents of a file from the Airkive
	static retrieve_text = function(_filepath, _validate = true)
	{
		// Retrieve using "file_retrieve"
		var _file = self.retrieve(_filepath, _validate);
		if (_file == -1) return _file;
		
		// Return String
		var _return_string = buffer_read(_file, buffer_text);
		
		// Delete File Buffer
		buffer_delete(_file);
		
		// Return File Contents
		return _return_string;
	}
	
	#endregion
	
	#region Find Functions
	
	/// @function retrieve_names([filepath], [extension])
	/// @argument filepath {String} [Filepath of the search]
	/// @argument extension {String} [Extension of the search]
	/// @return {Array<String>}
	/// @description Retrieve names in the Airkive based on given factors
	static retrieve_names = function(_filepath = "", _extension = "")
	{
		// Check File Path and Extension First
		var _filetable_names = variable_struct_get_names(filetable);
		if (_filepath == "" && _extension == "") return _filetable_names;
		
		// Return Names
		var _return_names = [  ];
		var _i = 0; repeat(array_length(_filetable_names))
		{
			// Filepath Check
			if (string_starts_with(_filetable_names[_i], _filepath) && (filename_ext(_filetable_names[_i]) == _extension || _extension == ""))
			{
				array_push(_return_names, _filetable_names[_i])
			}
			
			// Increment i
			_i++;
		}
		
		// Return Names
		return _return_names;
	}
	
	#endregion
	
	#region Other Functions
	
	/// @function build_directory_tree()
	/// @return {Undefined}
	/// @description Build a directory tree from the filetable
	static build_directory_tree = function()
	{
		// Create Root Directory
		directory_tree[$ "type"] = ENTRY_TYPE.DIRECTORY;
		directory_tree[$ "name"] = "root";
		
		// Get File Table Names
		var _filetable_names = variable_struct_get_names(filetable);
		var _i = 0; repeat(array_length(_filetable_names))
		{
			// Split File Table Entry
			var _split_path = string_split(_filetable_names[_i], "/");
			
			// Last Directory
			var _last_directory = directory_tree;
			
			// Split Path Loop
			var _j = 0; repeat(array_length(_split_path))
			{
				// Check for File or Directory
				if (_j == array_length(_split_path) - 1)
				{
					// File Entry
					var _file = {  };
					_file[$ "type"] = ENTRY_TYPE.FILE;
					_file[$ "name"] = _split_path[_j];
					_file[$ "offset"] = filetable[$ _filetable_names[_i]].offset;
					_file[$ "size"] = filetable[$ _filetable_names[_i]].size;
					_file[$ "size_compressed"] = filetable[$ _filetable_names[_i]].size_compressed;
					_file[$ "checksum"] = filetable[$ _filetable_names[_i]].checksum;
					_file[$ "source"] = filetable[$ _filetable_names[_i]].source;
					
					// Set File
					_last_directory[$ _split_path[_j]] = _file;
				}
				else
				{
					// Check if Directory Already Exists
					if (!variable_struct_exists(_last_directory, _split_path[_j]))
					{
						// Directory Entry
						var _directory = {  };
						_directory[$ "type"] = ENTRY_TYPE.DIRECTORY;
						_directory[$ "name"] = _split_path[_j];
					
						// Set Directory
						_last_directory[$ _split_path[_j]] = _directory;
					}
					_last_directory = _last_directory[$ _split_path[_j]];
				}
				
				// Increment j
				_j++;
			}
			
			// Inrement i
			_i++;
		}
	}
	
	#endregion
}