import brl.blitz
import brl.filesystem
import brl.map
import pub.zlib
import brl.basic
import brl.system
import brl.retro
import brl.glmax2d
APPEND_STATUS_CREATE%=0
APPEND_STATUS_CREATEAFTER%=1
APPEND_STATUS_ADDINZIP%=2
Z_DEFLATED%=8
Z_NO_COMPRESSION%=0
Z_BEST_SPEED%=1
Z_BEST_COMPRESSION%=9
Z_DEFAULT_COMPRESSION%=-1
UNZ_CASE_CHECK%=1
UNZ_NO_CASE_CHECK%=2
UNZ_OK%=0
UNZ_END_OF_LIST_OF_FILE%=-100
UNZ_EOF%=0
UNZ_PARAMERROR%=-102
UNZ_BADZIPFILE%=-103
UNZ_INTERNALERROR%=-104
UNZ_CRCERROR%=-105
ZLIB_FILEFUNC_SEEK_CUR%=1
ZLIB_FILEFUNC_SEEK_END%=2
ZLIB_FILEFUNC_SEEK_SET%=0
Z_OK%=0
Z_STREAM_END%=1
Z_NEED_DICT%=2
Z_ERRNO%=-1
Z_STREAM_ERROR%=-2
Z_DATA_ERROR%=-3
Z_MEM_ERROR%=-4
Z_BUF_ERROR%=-5
Z_VERSION_ERROR%=-6
unzOpen2@*(zipFileName$z,pzlib_filefunc_def@*)="unzOpen2"
unztell%(file@*)="unztell"
TBufferedStream^brl.stream.TStream{
.innerStream:brl.stream.TStream&
.pos_%&
.start_%&
.end_%&
.buf@&[]&
.bufPtr@*&
.bias1%&
.bias2%&
-New%()="_bb_TBufferedStream_New"
-Delete%()="_bb_TBufferedStream_Delete"
-Pos%()="_bb_TBufferedStream_Pos"
-Size%()="_bb_TBufferedStream_Size"
-Seek%(pos%)="_bb_TBufferedStream_Seek"
-Read%(dst@*,count%)="_bb_TBufferedStream_Read"
-Write%(buf@*,count%)="_bb_TBufferedStream_Write"
-Flush%()="_bb_TBufferedStream_Flush"
-Close%()="_bb_TBufferedStream_Close"
}="bb_TBufferedStream"
CreateBufferedStream:brl.stream.TStream(url:Object,bufSize%=4096,bForce%=0)="bb_CreateBufferedStream"
TZipStreamReadException^brl.stream.TStreamReadException{
.msg$&
-New%()="_bb_TZipStreamReadException_New"
-Delete%()="_bb_TZipStreamReadException_Delete"
-ToString$()="_bb_TZipStreamReadException_ToString"
}="bb_TZipStreamReadException"
SetZipStreamPasssword%(zipUrl$,password$)="bb_SetZipStreamPasssword"
ClearZipStreamPasssword%(zipUrl$)="bb_ClearZipStreamPasssword"
zipOpen@*(fileName$z,append%)="zipOpen"
zipClose%(zipFilePtr@*,archiveName$z)="zipClose"
zipOpenNewFileInZip%(zipFilePtr@*,fileName$z,zip_fileinfo@*,extrafield_local@*,size_extrafield_local%,extrafield_global@*,size_extrafield_global%,comment$z,compressionMethod%,level%)="zipOpenNewFileInZip"
zipOpenNewFileWithPassword%(zipFilePtr@*,fileName$z,zip_fileinfo@*,extrafield_local@*,size_extrafield_local%,extrafield_global@*,size_extrafield_global%,comment$z,compressionMethod%,level%,password$z)="zipOpenNewFileWithPassword"
zipWriteInFileInZip%(zipFilePtr@*,buffer@*,bufferLength%)="zipWriteInFileInZip"
unzOpen@*(zipFileName$z)="unzOpen"
unzLocateFile%(zipFilePtr@*,fileName$z,caseCheck%)="unzLocateFile"
unzOpenCurrentFile%(zipFilePtr@*)="unzOpenCurrentFile"
unzGetCurrentFileSize%(file@*)="unzGetCurrentFileSize"
unzOpenCurrentFilePassword%(file@*,password$z)="unzOpenCurrentFilePassword"
unzReadCurrentFile%(zipFilePtr@*,buffer@*,size%)="unzReadCurrentFile"
unzCloseCurrentFile%(zipFilePtr@*)="unzCloseCurrentFile"
unzClose%(zipFilePtr@*)="unzClose"
ZipFile^brl.blitz.Object{
.m_name$&
.m_zipFileList:TZipFileList&
-New%()="_bb_ZipFile_New"
-Delete%()="_bb_ZipFile_Delete"
-readFileList%()="_bb_ZipFile_readFileList"
-clearFileList%()="_bb_ZipFile_clearFileList"
-getFileCount%()="_bb_ZipFile_getFileCount"
-setName%(zipName$)="_bb_ZipFile_setName"
-getName$()="_bb_ZipFile_getName"
-getFileInfo:SZipFileEntry(index%)="_bb_ZipFile_getFileInfo"
-getFileInfoByName:SZipFileEntry(simpleFilename$)="_bb_ZipFile_getFileInfoByName"
}A="bb_ZipFile"
ZipWriter^ZipFile{
.m_zipFile@*&
.m_compressionLevel%&
-New%()="_bb_ZipWriter_New"
-Delete%()="_bb_ZipWriter_Delete"
-OpenZip%(name$,append%)="_bb_ZipWriter_OpenZip"
-SetCompressionLevel%(level%)="_bb_ZipWriter_SetCompressionLevel"
-AddFile%(fileName$,password$=$"")="_bb_ZipWriter_AddFile"
-AddStream%(data:brl.stream.TStream,fileName$,password$=$"")="_bb_ZipWriter_AddStream"
-CloseZip%(description$=$"")="_bb_ZipWriter_CloseZip"
}="bb_ZipWriter"
ZipReader^ZipFile{
.m_zipFile@*&
-New%()="_bb_ZipReader_New"
-Delete%()="_bb_ZipReader_Delete"
-OpenZip%(name$)="_bb_ZipReader_OpenZip"
-ExtractFile:brl.ramstream.TRamStream(fileName$,caseSensitive%=0,password$=$"")="_bb_ZipReader_ExtractFile"
-ExtractFileToDisk%(fileName$,outputFileName$,caseSensitive%=0,password$=$"")="_bb_ZipReader_ExtractFileToDisk"
-CloseZip%()="_bb_ZipReader_CloseZip"
}="bb_ZipReader"
ZipRamStream^brl.ramstream.TRamStream{
._data@&[]&
-New%()="_bb_ZipRamStream_New"
-Delete%()="_bb_ZipRamStream_Delete"
+ZCreate:brl.ramstream.TRamStream(size%,readable%,writeable%)="_bb_ZipRamStream_ZCreate"
}="bb_ZipRamStream"
TZipFileList^brl.blitz.Object{
.zipFile:brl.stream.TStream&
.FileList:brl.linkedlist.TList&
.IgnoreCase%&
.IgnorePaths%&
-New%()="_bb_TZipFileList_New"
-Delete%()="_bb_TZipFileList_Delete"
+create:TZipFileList(file:brl.stream.TStream,bIgnoreCase%,bIgnorePaths%)="_bb_TZipFileList_create"
-getFileCount%()="_bb_TZipFileList_getFileCount"
-getFileInfo:SZipFileEntry(index%)="_bb_TZipFileList_getFileInfo"
-findFile:SZipFileEntry(simpleFilename$)="_bb_TZipFileList_findFile"
-scanLocalHeader%()="_bb_TZipFileList_scanLocalHeader"
-extractFilename%(entry:SZipFileEntry)="_bb_TZipFileList_extractFilename"
-deletePathFromFilename%(filename$ Var)="_bb_TZipFileList_deletePathFromFilename"
}="bb_TZipFileList"
ZIP_INFO_IN_DATA_DESCRIPTOR@@=8
tm_zip^brl.blitz.Object{
.tm_sec%&
.tm_min%&
.tm_hour%&
.tm_mday%&
.tm_mon%&
.tm_year%&
-New%()="_bb_tm_zip_New"
-Delete%()="_bb_tm_zip_Delete"
}="bb_tm_zip"
zip_fileinfo^brl.blitz.Object{
.tmz_date:tm_zip&
.dosDate%%&
.internal_fa%%&
.external_fa%%&
-New%()="_bb_zip_fileinfo_New"
-Delete%()="_bb_zip_fileinfo_Delete"
-getBank:brl.bank.TBank()="_bb_zip_fileinfo_getBank"
}="bb_zip_fileinfo"
SZIPFileDataDescriptor^PACK_STRUCT{
size%=12
.CRC32%&
.CompressedSize%&
.UncompressedSize%&
-New%()="_bb_SZIPFileDataDescriptor_New"
-Delete%()="_bb_SZIPFileDataDescriptor_Delete"
-fillFromBank%(databank:brl.bank.TBank,offset%=0)="_bb_SZIPFileDataDescriptor_fillFromBank"
}="bb_SZIPFileDataDescriptor"
SZIPFileHeader^PACK_STRUCT{
size%=30
.Sig%&
.VersionToExtract@@&
.GeneralBitFlag@@&
.CompressionMethod@@&
.LastModFileTime@@&
.LastModFileDate@@&
.DataDescriptor:SZIPFileDataDescriptor&
.FilenameLength@@&
.ExtraFieldLength@@&
-New%()="_bb_SZIPFileHeader_New"
-Delete%()="_bb_SZIPFileHeader_Delete"
-fillFromBank%(databank:brl.bank.TBank,offset%=0)="_bb_SZIPFileHeader_fillFromBank"
}="bb_SZIPFileHeader"
SZipFileEntry^brl.blitz.Object{
.zipFileName$&
.simpleFileName$&
.path$&
.fileDataPosition%&
.header:SZIPFileHeader&
-New%()="_bb_SZipFileEntry_New"
-Delete%()="_bb_SZipFileEntry_Delete"
+create:SZipFileEntry()="_bb_SZipFileEntry_create"
-Less%(other:SZipFileEntry)="_bb_SZipFileEntry_Less"
-EqEq%(other:SZipFileEntry)="_bb_SZipFileEntry_EqEq"
-Compare%(other:Object)="_bb_SZipFileEntry_Compare"
}="bb_SZipFileEntry"
PACK_STRUCT^brl.blitz.Object{
size%&=mem("_bb_PACK_STRUCT_size")
-New%()="_bb_PACK_STRUCT_New"
-Delete%()="_bb_PACK_STRUCT_Delete"
-fillFromBank%(bank:brl.bank.TBank,start%)="_bb_PACK_STRUCT_fillFromBank"
-fillFromReader%(fileToRead:brl.stream.TStream,tbsize%,readeroffset%=0,bankoffset%=0)="_bb_PACK_STRUCT_fillFromReader"
-getBank:brl.bank.TBank()="_bb_PACK_STRUCT_getBank"
}="bb_PACK_STRUCT"
