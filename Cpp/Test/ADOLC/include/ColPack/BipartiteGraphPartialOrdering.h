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

#ifndef BIPARTITEGRAPHPARTIALORDERING_H
#define BIPARTITEGRAPHPARTIALORDERING_H

#define RIGHT_PARTIAL_DISTANCE_TWO COLUMN_PARTIAL_DISTANCE_TWO
#define LEFT_PARTIAL_DISTANCE_TWO ROW_PARTIAL_DISTANCE_TWO

namespace ColPack
{
	/** @ingroup group21
	 *  @brief class BipartiteGraphPartialOrdering in @link group21@endlink.

	 The BipartiteGraphPartialOrderingClass stores either the ordered row or column vertices as a
	 vector of vertex identifiers to be used by bipartite graph partial coloring methods.
	 */
	class BipartiteGraphPartialOrdering : public BipartiteGraphInputOutput
	{
	public:

		int OrderVertices(string s_OrderingVariant = "NATURAL", string s_ColoringVariant = "COLUMN_PARTIAL_DISTANCE_TWO");

	private:

		int CheckVertexOrdering(string s_VertexOrderingVariant);

	protected:

		double m_d_OrderingTime;

		string m_s_VertexOrderingVariant;

		vector<int> m_vi_OrderedVertices;

	public:

		BipartiteGraphPartialOrdering();

		~BipartiteGraphPartialOrdering();

		virtual void Clear();

		virtual void Reset();

		int RowNaturalOrdering();
		int ColumnNaturalOrdering();

		int RowRandomOrdering();
		int ColumnRandomOrdering();

		int RowLargestFirstOrdering();
		int ColumnLargestFirstOrdering();

		int RowSmallestLastOrdering();
		int RowSmallestLastOrdering_serial();
		int RowSmallestLastOrdering_OMP();
		int ColumnSmallestLastOrdering();
		int ColumnSmallestLastOrdering_serial();
		int ColumnSmallestLastOrdering_OMP();

		int RowIncidenceDegreeOrdering();
		int ColumnIncidenceDegreeOrdering();

                int RowDynamicLargestFirstOrdering();
                int ColumnDynamicLargestFirstOrdering();

		string GetVertexOrderingVariant();

		void GetOrderedVertices(vector<int> &output);

		void PrintVertexOrdering();
		
		double GetVertexOrderingTime();
	};
}
#endif
