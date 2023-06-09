/*	
	Airkiver
	An archiving tool for loading game resources packed in a airchive file
	Written by Alub
*/

function Airkiver(file) constructor
{
	// Construct File Table
	fileTable = constructFileTable(file);
	filePath = "";
	
	// Settings
	defaultToFileSystem = true;
	
	// Run CRC32
	generateCRC32Table();
	
	// File Table Construct
	static constructFileTable = function(_file)
	{
		// File Table Struct
		var _fileTable = {  };
		
		// Load The File Table
		var _buffer = buffer_load(_file);
		
		// File Magic
		var _fileMagic = buffer_read(_buffer, buffer_string);
		if (_fileMagic != "Airkive") throw ("Airkiver: Unrecognised File");
		
		// File Version
		var _fileVersion = buffer_read(_buffer, buffer_f32);
		if (_fileVersion != 1.1) throw ("Airkiver: Wrong file version");
		
		// File Count
		var _fileCount = buffer_read(_buffer, buffer_s32);
		
		// File Loop
		repeat (_fileCount)
		{
			// File Offset
			var _fileOffset = buffer_read(_buffer, buffer_s32);
			
			// File Size Uncompressed
			var _fileSize = buffer_read(_buffer, buffer_s32);
			
			// File Size Compressed (will equal size if file isn't compressed)
			var _fileSizeCompressed = buffer_read(_buffer, buffer_s32);
			
			// File Checksum
			var _fileChecksum = buffer_read(_buffer, buffer_u32);
			
			// File Source
			var _fileSource = buffer_read(_buffer, buffer_string);
			
			// File Name
			var _fileName = buffer_read(_buffer, buffer_string);
			
			// Add File To File Table
			variable_struct_set(_fileTable, _fileName, {
				offset:				_fileOffset,
				size:				_fileSize,
				sizeCompressed:		_fileSizeCompressed,
				checksum:			_fileChecksum,
				source:				_fileSource,
				name:				_fileName,
			});
		}
		
		// File Path
		filePath = filename_path(_file);
		
		// Delete Buffer
		buffer_delete(_buffer);
		
		// Return File Table
		return _fileTable;
	}
	
	// Get File
	static getFile = function(_fileName, _validate = false)
	{
		// Check If File Exists
		if (!variable_struct_exists(fileTable, _fileName) && (file_exists(_fileName) && defaultToFileSystem)) return buffer_load(_fileName);
		else if (!variable_struct_exists(fileTable, _fileName) && !file_exists(_fileName)) return -1;
		
		// File
		var _file = variable_struct_get(fileTable, _fileName);
		
		// Load File
		var _buffer = buffer_create(_file.sizeCompressed, buffer_fixed, 1);
		buffer_load_partial(_buffer, _file.source, _file.offset, _file.sizeCompressed, 0);
		
		// Check If File Is Compressed
		if (_file.sizeCompressed != _file.size)
		{
			var _returnBuffer = buffer_decompress(_buffer);
			buffer_delete(_buffer);
		}
		else
		{
			var _returnBuffer = _buffer;
		}
		
		// Validate
		if (_validate && (crc32(_buffer) != _file.checksum)) return -1; 
		
		// Return Buffer
		return _returnBuffer;
	}
	
	// CRC32 Written By JujuAdams
	static crc32 = function(_buffer, _offset = 0, _length = -1)
	{
		// Check Length
		if (_length != -1) _length = _offset + _length else _length = buffer_get_size(_buffer);
		
		
		// Generate CRC
		var crc = $FFFFFFFF;
		for(var i = _offset; i < _length; i++ ) crc = global.crc32table[ ( crc ^ buffer_peek( _buffer, i, buffer_u8 ) ) & $FF ] ^ ( crc >> 8 );
		return crc ^ $FFFFFFFF;
	}
	
	// Generate CRC Table
	static generateCRC32Table = function()
	{
		// Generate CRC32 Table
		var polynomial = $EDB88320;
			
		for(var i = 0; i <= $FF; i++) {
		    var crc = i;
        
		    repeat(8) {
		        if (crc & 1) {
		            crc = (crc >> 1) ^ polynomial;
		        } else {
		            crc = crc >> 1;
		        }
		    }
        
		    global.crc32table[i] = crc;
		}
	}
}