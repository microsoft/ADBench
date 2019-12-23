# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
from shared.defs import BA_NCAMPARAMS

class Vector:
    '''Dynamic vector of predefined max size.'''

    def __init__(self, capacity, data_type = int):
        '''

        Args:
            capacity (int): max vector capacity
            data_type: numpy data type defines type of a vector elements
        '''

        self.__max_capacity = capacity
        self.__data = np.empty(self.__max_capacity, dtype = data_type)
        self.__n = 0

    def __getitem__(self, i):
        return self.__data[i]

    def __setitem__(self, i, val):
        self.__data[i] = val
    
    def __len__(self):
        return self.__n

    def __iter__(self):
        return np.nditer(self.__data[:self.__n])

    def get_last(self):
        '''Returns the last item of the data.'''

        if self.__n > 0:
            return self.__data[self.__n - 1]
        else:
            return 0.0

    def push_back(self, val):
        '''Adds a new element to the end of the data.'''

        if self.__n < self.__max_capacity:
            self.__data[self.__n] = val
            self.__n += 1

    def clear(self):
        '''Resets data.'''

        self.__n = 0

    def storage_size(self):
        '''Returns storage size (max vector capacity).'''

        return self.__max_capacity



class BASparseMat:
    '''Holds information about sparse BA jacobian.
    
    Fields:
        n (int): number of cameras
        m (int): number of points
        p (int): number of observations

        nrows (int): number of matrix rows
        ncols (int): number of matrix columns

        rows (Vector): nrows + 1 vector containing indecies
                       to columns and values
        cols (Vector): holds info about columns
        vals (Vector): holds info about values
    '''

    def __init__(self, n = 0, m = 0, p = 0):
        '''
        
        Args:
            n (int): number of cameras
            m (int): number of points
            p (int): number of observations
        '''

        self.n = n
        self.m = m
        self.p = p

        self.nrows = 2 * p + p
        self.ncols = BA_NCAMPARAMS * self.n + 3 * self.m + self.p

        non_zero_number = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p
        self.rows = Vector(self.nrows + 1, np.int32)
        self.cols = Vector(non_zero_number, np.int32)
        self.vals = Vector(non_zero_number, np.float64)

        self.rows.push_back(0)

    def insert_reproj_err_block(self, obsIdx, camIdx, ptIdx, J):
        '''Inserts a new reprojection error block to the matrix.
        
        Args:
            obsIdx (int): index of an observation
            camIdx (int): index of a camera
            ptIdx (int): index of a point
            J (vector of float): value block in column major
        '''

        n_new_cols = BA_NCAMPARAMS + 3 + 1
        self.rows.push_back(self.rows.get_last() + n_new_cols)
        self.rows.push_back(self.rows.get_last() + n_new_cols)

        for i_row in range(2):
            for i in range(BA_NCAMPARAMS):
                self.cols.push_back(BA_NCAMPARAMS * camIdx + i)
                self.vals.push_back(J[2 * i + i_row])

            col_offset = BA_NCAMPARAMS * self.n
            val_offset = BA_NCAMPARAMS * 2

            for i in range(3):
                self.cols.push_back(col_offset + 3 * ptIdx + i)
                self.vals.push_back(J[val_offset + 2 * i + i_row])

            col_offset += 3 * self.m
            val_offset += 3 * 2
            self.cols.push_back(col_offset + obsIdx)
            self.vals.push_back(J[val_offset + i_row])

    def insert_w_err_block(self, wIdx, w_d):
        '''Inserts a new weight error block to the matrix.
        
        Args:
            wIdx (int): weight index
            w_d (float): value
        '''
        
        self.rows.push_back(self.rows.get_last() + 1)
        self.cols.push_back(BA_NCAMPARAMS * self.n + 3 * self.m + wIdx)
        self.vals.push_back(w_d)

    def clear(self):
        '''Clears matrix.'''

        self.rows.clear()
        self.cols.clear()
        self.vals.clear()
        self.rows.push_back(0)