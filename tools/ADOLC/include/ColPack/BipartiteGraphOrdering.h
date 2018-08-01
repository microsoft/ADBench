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

//using namespace std;

#ifndef BIPARTITEGRAPHORDERING_H
#define BIPARTITEGRAPHORDERING_H

using namespace std;

namespace ColPack
{
	/** @ingroup group22
	 *  @brief class BipartiteGraphOrdering in @link group22@endlink.

	 The BipartiteGraphOrderingClass stores the ordered row and column vertices as a vector of vertex
	 identifiers to be used by bipartite graph bicoloring methods. Since the row and column vertices use the same
	 set of identifiers, number of row vertices is added the column vertex identifiers in the ordered vector.
	 */
	class BipartiteGraphOrdering : public BipartiteGraphVertexCover
	{
	public:

		int OrderVertices(string s_OrderingVariant);

	private:

		//Private Function 3401
		int CheckVertexOrdering(string s_VertexOrderingVariant);

	protected:

		double m_d_OrderingTime;

		string m_s_VertexOrderingVariant;

		vector<int> m_vi_OrderedVertices;

	public:

		BipartiteGraphOrdering();

		~BipartiteGraphOrdering();

		virtual void Clear();

		virtual void Reset();

		int NaturalOrdering();

		int RandomOrdering();

		int LargestFirstOrdering();

		int SmallestLastOrdering();

		int IncidenceDegreeOrdering();

		int DynamicLargestFirstOrdering();

		int SelectiveLargestFirstOrdering();

		int SelectiveSmallestLastOrdering();

		int SelectiveIncidenceDegreeOrdering();

		string GetVertexOrderingVariant();

		void GetOrderedVertices(vector<int> &output);

		void PrintVertexOrdering();
		
		double GetVertexOrderingTime();
	};
}
#endif
