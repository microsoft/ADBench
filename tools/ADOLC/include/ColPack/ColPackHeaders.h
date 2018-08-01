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

/************************************************************************************/
/*																					*/
/*  Headers.h (Header of header files) 												*/
/*																					*/
/************************************************************************************/
#ifndef HEADER_H
#define HEADER_H

#include "Definitions.h"

#ifdef SYSTEM_TIME

#include <sys/times.h>

#else

#include <ctime>

#endif

#include <iostream>
#include <fstream>
#include <sstream>
#include <ctime>
#include <iomanip>
#include <string>
#include <cstdlib>
#include <cstdarg>

#include <list>
#include <map>
#include <vector>
#include <set>
#include <queue>

#include <algorithm>
#include <iterator>
#include <utility>	//for pair<dataType1, dataType2>

#ifdef _OPENMP
	#include <omp.h>
#endif

#include "Pause.h"
#include "File.h"
#include "Timer.h"
#include "MatrixDeallocation.h"
#include "mmio.h"
#include "current_time.h"
#include "CoutLock.h"

#include "StringTokenizer.h"
#include "DisjointSets.h"

#include "GraphCore.h"
#include "GraphInputOutput.h"
#include "GraphOrdering.h"
#include "GraphColoring.h"
#include "GraphColoringInterface.h"

#include "BipartiteGraphCore.h"
#include "BipartiteGraphInputOutput.h"
#include "BipartiteGraphVertexCover.h"
#include "BipartiteGraphPartialOrdering.h"
#include "BipartiteGraphOrdering.h"
#include "BipartiteGraphBicoloring.h"
#include "BipartiteGraphPartialColoring.h"
#include "BipartiteGraphBicoloringInterface.h"
#include "BipartiteGraphPartialColoringInterface.h"

#include "RecoveryCore.h"
#include "HessianRecovery.h"
#include "JacobianRecovery1D.h"
#include "JacobianRecovery2D.h"

#include "extra.h"

#endif
