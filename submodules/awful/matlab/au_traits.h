// ----------------------------------------------------------------------------

template <class T>
struct mlx_numeric_traits {
};

template <>
struct mlx_numeric_traits<unsigned int> {
  typedef unsigned int wide_t;
};

template <>
struct mlx_numeric_traits<mlx_uint8> {
  typedef unsigned int wide_t;
};

template <>
struct mlx_numeric_traits<mlx_single> {
  typedef mlx_double wide_t;
};

template <>
struct mlx_numeric_traits<mlx_double> {
  typedef mlx_double wide_t;
};

// ----------------------------------------------------------------------------

template <class T>
struct mlx_traits {
};

template <>
struct mlx_traits<mlx_uint8> {
  typedef mlx_uint8 T;
  typedef mlx_numeric_traits<T>::wide_t wide_t;
  static T colour_max() { return 255; }
  static T narrowing_divide_by_max(wide_t val) { return T(val / 255); }
};

template <>
struct mlx_traits<mlx_single> {
  typedef mlx_single T;
  typedef mlx_numeric_traits<T>::wide_t wide_t;

  static T colour_max() { return 1.0f; }
  static T narrowing_divide_by_max(wide_t t) { return T(t); }
};

template <>
struct mlx_traits<mlx_double> {
  typedef mlx_double T;
  typedef mlx_numeric_traits<T>::wide_t wide_t;

  static T colour_max() { return 1.0; }
  static T narrowing_divide_by_max(wide_t t) { return T(t); }
};

template <class T>
bool assert_equal(T*,T*) {};

template <class T1, class T2>
struct mlp_pairwise_traits {
  typedef typename mlx_numeric_traits<T1>::wide_t wide1_t;
  typedef typename mlx_numeric_traits<wide1_t>::wide_t wide_t;
  
  typedef typename mlx_numeric_traits<wide_t>::wide_t wide_t_from2;

  // Check that wide of wide is the same for both...
  void f() { assert_equal((wide_t*)0, (wide_t_from2*)0); }
};

// ----------------------------------------------------------------------------

template <class T1, class T2>
inline
typename mlp_pairwise_traits<T1,T2>::wide_t
widening_product(T1 a, T2 b)
{
  typedef typename mlp_pairwise_traits<T1,T2>::wide_t out_t;
  return out_t(out_t(a) * out_t(b));
}

inline unsigned int saturating_add(unsigned int a, unsigned int b)
{
  return a + b;
}


inline double saturating_add(double a, double b)
{
  return a + b;
}
