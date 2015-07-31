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

#include<iostream>
#include<string>
#include<vector>

using namespace std;

/*Convert command line parameters to vector arg for easiness
Input: argc, argv
Output: arg
Precondition: arg is empty
*/
void createArgs(int argc, const char* argv[], vector<string>& arg);

//find argument in vector arg
int findArg(string argument, vector<string>& arg);

//SAMPLE main.cpp
/*
#include "command_line_parameter_processor.h"

using namespace std;

int commandLineProcessing(vector<string>& arg);

int main(int argc, const char* argv[] ) {
	vector<string> arg;

	//get the list of arguments
	createArgs(argc, argv, arg);

	//process those arguments
	commandLineProcessing(arg);

	//...

	return 0;
}

int commandLineProcessing(vector<string>& arg) {

	int num=findArg("-r", arg);
	if (num!=-1) //argument is found, do something
	{
		//...
	}

	if (findArg("-append", arg) != -1 || findArg("-app", arg) != -1) //append output to the existing file
	{
		output_append = true;
	}

	//"-suffix" has priority over "-suf", i.e., if both "-suffix" and "-suf" are specified, "-suffix <output_suffix>" will be used
	int result;
	result = findArg("-suffix", arg);
	if (result == -1) result = findArg("-suf", arg);
	if (result != -1) //suffix is specified
	{
		output_suffix = arg[result+1];
	}

	return 0;
}
//*/


