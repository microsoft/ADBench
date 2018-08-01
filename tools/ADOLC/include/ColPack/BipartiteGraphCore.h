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

using namespace std;

#ifndef BIPARTITEGRAPHCORE_H
#define BIPARTITEGRAPHCORE_H

namespace ColPack
{
	/** @ingroup group2
	 *  @brief class BipartiteGraphCore in @link group2@endlink.

	 Base class for Bipartite Graph. Define a Bipartite Graph: left vertices, right vertices and edges; and its statisitcs: max, min and average degree.
	*/
	class BipartiteGraphCore
	{
	public: //DOCUMENTED

		/// LeftVertexCount = RowVertexCount = m_vi_LeftVertices.size() -1
		int GetRowVertexCount();
		/// LeftVertexCount = RowVertexCount = m_vi_LeftVertices.size() -1
		int GetLeftVertexCount();

		
		/// RightVertexCount = ColumnVertexCount = m_vi_RightVertices.size() -1
		int GetColumnVertexCount();
		/// RightVertexCount = ColumnVertexCount = m_vi_RightVertices.size() -1
		int GetRightVertexCount();

		bool operator==(const BipartiteGraphCore &other) const;

	protected:

		int m_i_MaximumLeftVertexDegree;
		int m_i_MaximumRightVertexDegree;
		int m_i_MaximumVertexDegree;

		int m_i_MinimumLeftVertexDegree;
		int m_i_MinimumRightVertexDegree;
		int m_i_MinimumVertexDegree;

		double m_d_AverageLeftVertexDegree;
		double m_d_AverageRightVertexDegree;
		double m_d_AverageVertexDegree;

		string m_s_InputFile;

		vector<int> m_vi_LeftVertices;
		vector<int> m_vi_RightVertices;

		vector<int> m_vi_Edges;

		map< int, map<int, int> > m_mimi2_VertexEdgeMap;
		

	public:
		
		virtual ~BipartiteGraphCore(){}

		virtual void Clear();
		
		string GetInputFile();
		
		vector<int>* GetLeftVerticesPtr() ;
		vector<int>* GetRightVerticesPtr() ;

		void GetRowVertices(vector<int> &output) const;
		void GetLeftVertices(vector<int> &output) const;
		
		void GetColumnVertices(vector<int> &output) const;
		void GetRightVertices(vector<int> &output) const;

		unsigned int GetRowVertices(unsigned int** ip2_RowVertex);
		unsigned int GetColumnIndices(unsigned int** ip2_ColumnIndex);

		void GetEdges(vector<int> &output) const;
		
		void GetVertexEdgeMap(map< int, map<int, int> > &output);

		int GetEdgeCount();

		int GetMaximumRowVertexDegree();

		int GetMaximumColumnVertexDegree();

		int GetMaximumVertexDegree();

		int GetMinimumRowVertexDegree();

		int GetMinimumColumnVertexDegree();

		int GetMinimumVertexDegree();

		double GetAverageRowVertexDegree();
		
		double GetAverageColumnVertexDegree();
		
		double GetAverageVertexDegree();
	};
}
#endif
