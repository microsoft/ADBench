/************************************************************************************
    Copyright (C) 2005-2008 Assefaw H. Gebremedhin, Arijit Tarafdar, Duc Nguyen,
    Alex Pothen

    This file is part of ColPack.

    ColPack is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ColPack is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with ColPack.  If not, see <http://www.gnu.org/licenses/>.
************************************************************************************/

#ifndef FILE_H
#define FILE_H

#include<string>

using namespace std;

//#undef _WIN32

//define system-dependent directory separator
#ifdef _WIN32	//Windows
#define DIR_SEPARATOR "\\"
#else			//*nix
#define DIR_SEPARATOR "/"
#endif


namespace ColPack 
{
	/** @ingroup group4
	 *  @brief class File in @link group4@endlink.

	 The File class is used to process file name. It should work on both Windows and *nix. A File object will
	 take a file name, parse and separate it into 3 parts: path (name prefix), name, and file extension.
	 */
	class File
	{
	  private:
	    
		string path; //including the last DIR_SEPARATOR
		string name;
		string fileExtension; //excluding the '.'

	  public:
	    
		File();

		File(string fileName);

		void Parse(string newFileName);

		string GetPath() const;

		string GetName() const;

		///GetFileExtension excluding the '.'
		string GetFileExtension() const; 

		string GetFullName() const;

		void SetPath(string newPath);

		void SetName(string newName);

		void SetFileExtension(string newFileExtension);

	};

	///Tell whether or not the file format is MatrixMarket from its extension
	bool isMatrixMarketFormat(string s_fileExtension);

	///Tell whether or not the file format is HarwellBoeing from its extension
	bool isHarwellBoeingFormat(string s_fileExtension);

	///Tell whether or not the file format is MeTiS from its extension
	bool isMeTiSFormat(string s_fileExtension);
}
#endif
