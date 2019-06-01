#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <stdint.h>
#undef NDEBUG
#include <assert.h>
// Start of panic.h.

#include <stdarg.h>

static const char *fut_progname;

static void panic(int eval, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
        fprintf(stderr, "%s: ", fut_progname);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
        exit(eval);
}

/* For generating arbitrary-sized error messages.  It is the callers
   responsibility to free the buffer at some point. */
static char* msgprintf(const char *s, ...) {
  va_list vl;
  va_start(vl, s);
  size_t needed = 1 + vsnprintf(NULL, 0, s, vl);
  char *buffer = (char*) malloc(needed);
  va_start(vl, s); /* Must re-init. */
  vsnprintf(buffer, needed, s, vl);
  return buffer;
}

// End of panic.h.

// Start of timing.h.

// The function get_wall_time() returns the wall time in microseconds
// (with an unspecified offset).

#ifdef _WIN32

#include <windows.h>

static int64_t get_wall_time(void) {
  LARGE_INTEGER time,freq;
  assert(QueryPerformanceFrequency(&freq));
  assert(QueryPerformanceCounter(&time));
  return ((double)time.QuadPart / freq.QuadPart) * 1000000;
}

#else
/* Assuming POSIX */

#include <time.h>
#include <sys/time.h>

static int64_t get_wall_time(void) {
  struct timeval time;
  assert(gettimeofday(&time,NULL) == 0);
  return time.tv_sec * 1000000 + time.tv_usec;
}

#endif

// End of timing.h.

#ifdef _MSC_VER
#define inline __inline
#endif
#include <string.h>
#include <inttypes.h>
#include <ctype.h>
#include <errno.h>
#include <assert.h>
// Start of lock.h.

/* A very simple cross-platform implementation of locks.  Uses
   pthreads on Unix and some Windows thing there.  Futhark's
   host-level code is not multithreaded, but user code may be, so we
   need some mechanism for ensuring atomic access to API functions.
   This is that mechanism.  It is not exposed to user code at all, so
   we do not have to worry about name collisions. */

#ifdef _WIN32

typedef HANDLE lock_t;

static lock_t create_lock(lock_t *lock) {
  *lock = CreateMutex(NULL,  /* Default security attributes. */
                      FALSE, /* Initially unlocked. */
                      NULL); /* Unnamed. */
}

static void lock_lock(lock_t *lock) {
  assert(WaitForSingleObject(*lock, INFINITE) == WAIT_OBJECT_0);
}

static void lock_unlock(lock_t *lock) {
  assert(ReleaseMutex(*lock));
}

static void free_lock(lock_t *lock) {
  CloseHandle(*lock);
}

#else
/* Assuming POSIX */

#include <pthread.h>

typedef pthread_mutex_t lock_t;

static void create_lock(lock_t *lock) {
  int r = pthread_mutex_init(lock, NULL);
  assert(r == 0);
}

static void lock_lock(lock_t *lock) {
  int r = pthread_mutex_lock(lock);
  assert(r == 0);
}

static void lock_unlock(lock_t *lock) {
  int r = pthread_mutex_unlock(lock);
  assert(r == 0);
}

static void free_lock(lock_t *lock) {
  /* Nothing to do for pthreads. */
  (void)lock;
}

#endif

// End of lock.h.

struct memblock {
    int *references;
    char *mem;
    int64_t size;
    const char *desc;
} ;
struct futhark_context_config {
    int debugging;
} ;
struct futhark_context_config *futhark_context_config_new()
{
    struct futhark_context_config *cfg =
                                  (struct futhark_context_config *) malloc(sizeof(struct futhark_context_config));
    
    if (cfg == NULL)
        return NULL;
    cfg->debugging = 0;
    return cfg;
}
void futhark_context_config_free(struct futhark_context_config *cfg)
{
    free(cfg);
}
void futhark_context_config_set_debugging(struct futhark_context_config *cfg,
                                          int detail)
{
    cfg->debugging = detail;
}
void futhark_context_config_set_logging(struct futhark_context_config *cfg,
                                        int detail)
{
    /* Does nothing for this backend. */
    cfg = cfg;
    detail = detail;
}
struct futhark_context {
    int detail_memory;
    int debugging;
    lock_t lock;
    char *error;
    int64_t peak_mem_usage_default;
    int64_t cur_mem_usage_default;
} ;
struct futhark_context *futhark_context_new(struct futhark_context_config *cfg)
{
    struct futhark_context *ctx =
                           (struct futhark_context *) malloc(sizeof(struct futhark_context));
    
    if (ctx == NULL)
        return NULL;
    ctx->detail_memory = cfg->debugging;
    ctx->debugging = cfg->debugging;
    ctx->error = NULL;
    create_lock(&ctx->lock);
    ctx->peak_mem_usage_default = 0;
    ctx->cur_mem_usage_default = 0;
    return ctx;
}
void futhark_context_free(struct futhark_context *ctx)
{
    free_lock(&ctx->lock);
    free(ctx);
}
int futhark_context_sync(struct futhark_context *ctx)
{
    ctx = ctx;
    return 0;
}
char *futhark_context_get_error(struct futhark_context *ctx)
{
    char *error = ctx->error;
    
    ctx->error = NULL;
    return error;
}
static int memblock_unref(struct futhark_context *ctx, struct memblock *block,
                          const char *desc)
{
    if (block->references != NULL) {
        *block->references -= 1;
        if (ctx->detail_memory)
            fprintf(stderr,
                    "Unreferencing block %s (allocated as %s) in %s: %d references remaining.\n",
                    desc, block->desc, "default space", *block->references);
        if (*block->references == 0) {
            ctx->cur_mem_usage_default -= block->size;
            free(block->mem);
            free(block->references);
            if (ctx->detail_memory)
                fprintf(stderr,
                        "%lld bytes freed (now allocated: %lld bytes)\n",
                        (long long) block->size,
                        (long long) ctx->cur_mem_usage_default);
        }
        block->references = NULL;
    }
    return 0;
}
static int memblock_alloc(struct futhark_context *ctx, struct memblock *block,
                          int64_t size, const char *desc)
{
    if (size < 0)
        panic(1, "Negative allocation of %lld bytes attempted for %s in %s.\n",
              (long long) size, desc, "default space",
              ctx->cur_mem_usage_default);
    
    int ret = memblock_unref(ctx, block, desc);
    
    ctx->cur_mem_usage_default += size;
    if (ctx->detail_memory)
        fprintf(stderr,
                "Allocating %lld bytes for %s in %s (then allocated: %lld bytes)",
                (long long) size, desc, "default space",
                (long long) ctx->cur_mem_usage_default);
    if (ctx->cur_mem_usage_default > ctx->peak_mem_usage_default) {
        ctx->peak_mem_usage_default = ctx->cur_mem_usage_default;
        if (ctx->detail_memory)
            fprintf(stderr, " (new peak).\n");
    } else if (ctx->detail_memory)
        fprintf(stderr, ".\n");
    block->mem = (char *) malloc(size);
    block->references = (int *) malloc(sizeof(int));
    *block->references = 1;
    block->size = size;
    block->desc = desc;
    return ret;
}
static int memblock_set(struct futhark_context *ctx, struct memblock *lhs,
                        struct memblock *rhs, const char *lhs_desc)
{
    int ret = memblock_unref(ctx, lhs, lhs_desc);
    
    (*rhs->references)++;
    *lhs = *rhs;
    return ret;
}
void futhark_debugging_report(struct futhark_context *ctx)
{
    if (ctx->detail_memory) {
        fprintf(stderr, "Peak memory usage for default space: %lld bytes.\n",
                (long long) ctx->peak_mem_usage_default);
    }
    if (ctx->debugging) { }
}
static int futrts_rev_gmm_objective(struct futhark_context *ctx,
                                    struct memblock *out_mem_p_69641,
                                    int32_t *out_out_arrsizze_69642,
                                    struct memblock *out_mem_p_69643,
                                    int32_t *out_out_arrsizze_69644,
                                    int32_t *out_out_arrsizze_69645,
                                    struct memblock *out_mem_p_69646,
                                    int32_t *out_out_arrsizze_69647,
                                    int32_t *out_out_arrsizze_69648,
                                    struct memblock *out_mem_p_69649,
                                    int32_t *out_out_arrsizze_69650,
                                    int32_t *out_out_arrsizze_69651,
                                    struct memblock x_mem_69258,
                                    struct memblock alphas_mem_69259,
                                    struct memblock means_mem_69260,
                                    struct memblock qs_mem_69261,
                                    struct memblock icf_mem_69262,
                                    int32_t N_68495, int32_t D_68496,
                                    int32_t K_68497, int32_t K_68498,
                                    int32_t D_68499, int32_t K_68500,
                                    int32_t D_68501, int32_t K_68502,
                                    int32_t triD_68503,
                                    double wishart_gamma_68509,
                                    int32_t wishart_m_68510, double d_r_68511);
static int futrts_gmm_objective(struct futhark_context *ctx,
                                double *out_scalar_out_69652,
                                struct memblock x_mem_69258,
                                struct memblock alphas_mem_69259,
                                struct memblock means_mem_69260,
                                struct memblock qs_mem_69261,
                                struct memblock icf_mem_69262, int32_t N_68236,
                                int32_t D_68237, int32_t K_68238,
                                int32_t K_68239, int32_t D_68240,
                                int32_t K_68241, int32_t D_68242,
                                int32_t K_68243, int32_t triD_68244,
                                double wishart_gamma_68250,
                                int32_t wishart_m_68251);
static inline int8_t add8(int8_t x, int8_t y)
{
    return x + y;
}
static inline int16_t add16(int16_t x, int16_t y)
{
    return x + y;
}
static inline int32_t add32(int32_t x, int32_t y)
{
    return x + y;
}
static inline int64_t add64(int64_t x, int64_t y)
{
    return x + y;
}
static inline int8_t sub8(int8_t x, int8_t y)
{
    return x - y;
}
static inline int16_t sub16(int16_t x, int16_t y)
{
    return x - y;
}
static inline int32_t sub32(int32_t x, int32_t y)
{
    return x - y;
}
static inline int64_t sub64(int64_t x, int64_t y)
{
    return x - y;
}
static inline int8_t mul8(int8_t x, int8_t y)
{
    return x * y;
}
static inline int16_t mul16(int16_t x, int16_t y)
{
    return x * y;
}
static inline int32_t mul32(int32_t x, int32_t y)
{
    return x * y;
}
static inline int64_t mul64(int64_t x, int64_t y)
{
    return x * y;
}
static inline uint8_t udiv8(uint8_t x, uint8_t y)
{
    return x / y;
}
static inline uint16_t udiv16(uint16_t x, uint16_t y)
{
    return x / y;
}
static inline uint32_t udiv32(uint32_t x, uint32_t y)
{
    return x / y;
}
static inline uint64_t udiv64(uint64_t x, uint64_t y)
{
    return x / y;
}
static inline uint8_t umod8(uint8_t x, uint8_t y)
{
    return x % y;
}
static inline uint16_t umod16(uint16_t x, uint16_t y)
{
    return x % y;
}
static inline uint32_t umod32(uint32_t x, uint32_t y)
{
    return x % y;
}
static inline uint64_t umod64(uint64_t x, uint64_t y)
{
    return x % y;
}
static inline int8_t sdiv8(int8_t x, int8_t y)
{
    int8_t q = x / y;
    int8_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int16_t sdiv16(int16_t x, int16_t y)
{
    int16_t q = x / y;
    int16_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int32_t sdiv32(int32_t x, int32_t y)
{
    int32_t q = x / y;
    int32_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int64_t sdiv64(int64_t x, int64_t y)
{
    int64_t q = x / y;
    int64_t r = x % y;
    
    return q - ((r != 0 && r < 0 != y < 0) ? 1 : 0);
}
static inline int8_t smod8(int8_t x, int8_t y)
{
    int8_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int16_t smod16(int16_t x, int16_t y)
{
    int16_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int32_t smod32(int32_t x, int32_t y)
{
    int32_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int64_t smod64(int64_t x, int64_t y)
{
    int64_t r = x % y;
    
    return r + (r == 0 || (x > 0 && y > 0) || (x < 0 && y < 0) ? 0 : y);
}
static inline int8_t squot8(int8_t x, int8_t y)
{
    return x / y;
}
static inline int16_t squot16(int16_t x, int16_t y)
{
    return x / y;
}
static inline int32_t squot32(int32_t x, int32_t y)
{
    return x / y;
}
static inline int64_t squot64(int64_t x, int64_t y)
{
    return x / y;
}
static inline int8_t srem8(int8_t x, int8_t y)
{
    return x % y;
}
static inline int16_t srem16(int16_t x, int16_t y)
{
    return x % y;
}
static inline int32_t srem32(int32_t x, int32_t y)
{
    return x % y;
}
static inline int64_t srem64(int64_t x, int64_t y)
{
    return x % y;
}
static inline int8_t smin8(int8_t x, int8_t y)
{
    return x < y ? x : y;
}
static inline int16_t smin16(int16_t x, int16_t y)
{
    return x < y ? x : y;
}
static inline int32_t smin32(int32_t x, int32_t y)
{
    return x < y ? x : y;
}
static inline int64_t smin64(int64_t x, int64_t y)
{
    return x < y ? x : y;
}
static inline uint8_t umin8(uint8_t x, uint8_t y)
{
    return x < y ? x : y;
}
static inline uint16_t umin16(uint16_t x, uint16_t y)
{
    return x < y ? x : y;
}
static inline uint32_t umin32(uint32_t x, uint32_t y)
{
    return x < y ? x : y;
}
static inline uint64_t umin64(uint64_t x, uint64_t y)
{
    return x < y ? x : y;
}
static inline int8_t smax8(int8_t x, int8_t y)
{
    return x < y ? y : x;
}
static inline int16_t smax16(int16_t x, int16_t y)
{
    return x < y ? y : x;
}
static inline int32_t smax32(int32_t x, int32_t y)
{
    return x < y ? y : x;
}
static inline int64_t smax64(int64_t x, int64_t y)
{
    return x < y ? y : x;
}
static inline uint8_t umax8(uint8_t x, uint8_t y)
{
    return x < y ? y : x;
}
static inline uint16_t umax16(uint16_t x, uint16_t y)
{
    return x < y ? y : x;
}
static inline uint32_t umax32(uint32_t x, uint32_t y)
{
    return x < y ? y : x;
}
static inline uint64_t umax64(uint64_t x, uint64_t y)
{
    return x < y ? y : x;
}
static inline uint8_t shl8(uint8_t x, uint8_t y)
{
    return x << y;
}
static inline uint16_t shl16(uint16_t x, uint16_t y)
{
    return x << y;
}
static inline uint32_t shl32(uint32_t x, uint32_t y)
{
    return x << y;
}
static inline uint64_t shl64(uint64_t x, uint64_t y)
{
    return x << y;
}
static inline uint8_t lshr8(uint8_t x, uint8_t y)
{
    return x >> y;
}
static inline uint16_t lshr16(uint16_t x, uint16_t y)
{
    return x >> y;
}
static inline uint32_t lshr32(uint32_t x, uint32_t y)
{
    return x >> y;
}
static inline uint64_t lshr64(uint64_t x, uint64_t y)
{
    return x >> y;
}
static inline int8_t ashr8(int8_t x, int8_t y)
{
    return x >> y;
}
static inline int16_t ashr16(int16_t x, int16_t y)
{
    return x >> y;
}
static inline int32_t ashr32(int32_t x, int32_t y)
{
    return x >> y;
}
static inline int64_t ashr64(int64_t x, int64_t y)
{
    return x >> y;
}
static inline uint8_t and8(uint8_t x, uint8_t y)
{
    return x & y;
}
static inline uint16_t and16(uint16_t x, uint16_t y)
{
    return x & y;
}
static inline uint32_t and32(uint32_t x, uint32_t y)
{
    return x & y;
}
static inline uint64_t and64(uint64_t x, uint64_t y)
{
    return x & y;
}
static inline uint8_t or8(uint8_t x, uint8_t y)
{
    return x | y;
}
static inline uint16_t or16(uint16_t x, uint16_t y)
{
    return x | y;
}
static inline uint32_t or32(uint32_t x, uint32_t y)
{
    return x | y;
}
static inline uint64_t or64(uint64_t x, uint64_t y)
{
    return x | y;
}
static inline uint8_t xor8(uint8_t x, uint8_t y)
{
    return x ^ y;
}
static inline uint16_t xor16(uint16_t x, uint16_t y)
{
    return x ^ y;
}
static inline uint32_t xor32(uint32_t x, uint32_t y)
{
    return x ^ y;
}
static inline uint64_t xor64(uint64_t x, uint64_t y)
{
    return x ^ y;
}
static inline char ult8(uint8_t x, uint8_t y)
{
    return x < y;
}
static inline char ult16(uint16_t x, uint16_t y)
{
    return x < y;
}
static inline char ult32(uint32_t x, uint32_t y)
{
    return x < y;
}
static inline char ult64(uint64_t x, uint64_t y)
{
    return x < y;
}
static inline char ule8(uint8_t x, uint8_t y)
{
    return x <= y;
}
static inline char ule16(uint16_t x, uint16_t y)
{
    return x <= y;
}
static inline char ule32(uint32_t x, uint32_t y)
{
    return x <= y;
}
static inline char ule64(uint64_t x, uint64_t y)
{
    return x <= y;
}
static inline char slt8(int8_t x, int8_t y)
{
    return x < y;
}
static inline char slt16(int16_t x, int16_t y)
{
    return x < y;
}
static inline char slt32(int32_t x, int32_t y)
{
    return x < y;
}
static inline char slt64(int64_t x, int64_t y)
{
    return x < y;
}
static inline char sle8(int8_t x, int8_t y)
{
    return x <= y;
}
static inline char sle16(int16_t x, int16_t y)
{
    return x <= y;
}
static inline char sle32(int32_t x, int32_t y)
{
    return x <= y;
}
static inline char sle64(int64_t x, int64_t y)
{
    return x <= y;
}
static inline int8_t pow8(int8_t x, int8_t y)
{
    int8_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int16_t pow16(int16_t x, int16_t y)
{
    int16_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int32_t pow32(int32_t x, int32_t y)
{
    int32_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline int64_t pow64(int64_t x, int64_t y)
{
    int64_t res = 1, rem = y;
    
    while (rem != 0) {
        if (rem & 1)
            res *= x;
        rem >>= 1;
        x *= x;
    }
    return res;
}
static inline bool itob_i8_bool(int8_t x)
{
    return x;
}
static inline bool itob_i16_bool(int16_t x)
{
    return x;
}
static inline bool itob_i32_bool(int32_t x)
{
    return x;
}
static inline bool itob_i64_bool(int64_t x)
{
    return x;
}
static inline int8_t btoi_bool_i8(bool x)
{
    return x;
}
static inline int16_t btoi_bool_i16(bool x)
{
    return x;
}
static inline int32_t btoi_bool_i32(bool x)
{
    return x;
}
static inline int64_t btoi_bool_i64(bool x)
{
    return x;
}
#define sext_i8_i8(x) ((int8_t) (int8_t) x)
#define sext_i8_i16(x) ((int16_t) (int8_t) x)
#define sext_i8_i32(x) ((int32_t) (int8_t) x)
#define sext_i8_i64(x) ((int64_t) (int8_t) x)
#define sext_i16_i8(x) ((int8_t) (int16_t) x)
#define sext_i16_i16(x) ((int16_t) (int16_t) x)
#define sext_i16_i32(x) ((int32_t) (int16_t) x)
#define sext_i16_i64(x) ((int64_t) (int16_t) x)
#define sext_i32_i8(x) ((int8_t) (int32_t) x)
#define sext_i32_i16(x) ((int16_t) (int32_t) x)
#define sext_i32_i32(x) ((int32_t) (int32_t) x)
#define sext_i32_i64(x) ((int64_t) (int32_t) x)
#define sext_i64_i8(x) ((int8_t) (int64_t) x)
#define sext_i64_i16(x) ((int16_t) (int64_t) x)
#define sext_i64_i32(x) ((int32_t) (int64_t) x)
#define sext_i64_i64(x) ((int64_t) (int64_t) x)
#define zext_i8_i8(x) ((uint8_t) (uint8_t) x)
#define zext_i8_i16(x) ((uint16_t) (uint8_t) x)
#define zext_i8_i32(x) ((uint32_t) (uint8_t) x)
#define zext_i8_i64(x) ((uint64_t) (uint8_t) x)
#define zext_i16_i8(x) ((uint8_t) (uint16_t) x)
#define zext_i16_i16(x) ((uint16_t) (uint16_t) x)
#define zext_i16_i32(x) ((uint32_t) (uint16_t) x)
#define zext_i16_i64(x) ((uint64_t) (uint16_t) x)
#define zext_i32_i8(x) ((uint8_t) (uint32_t) x)
#define zext_i32_i16(x) ((uint16_t) (uint32_t) x)
#define zext_i32_i32(x) ((uint32_t) (uint32_t) x)
#define zext_i32_i64(x) ((uint64_t) (uint32_t) x)
#define zext_i64_i8(x) ((uint8_t) (uint64_t) x)
#define zext_i64_i16(x) ((uint16_t) (uint64_t) x)
#define zext_i64_i32(x) ((uint32_t) (uint64_t) x)
#define zext_i64_i64(x) ((uint64_t) (uint64_t) x)
static inline float fdiv32(float x, float y)
{
    return x / y;
}
static inline float fadd32(float x, float y)
{
    return x + y;
}
static inline float fsub32(float x, float y)
{
    return x - y;
}
static inline float fmul32(float x, float y)
{
    return x * y;
}
static inline float fmin32(float x, float y)
{
    return x < y ? x : y;
}
static inline float fmax32(float x, float y)
{
    return x < y ? y : x;
}
static inline float fpow32(float x, float y)
{
    return pow(x, y);
}
static inline char cmplt32(float x, float y)
{
    return x < y;
}
static inline char cmple32(float x, float y)
{
    return x <= y;
}
static inline float sitofp_i8_f32(int8_t x)
{
    return x;
}
static inline float sitofp_i16_f32(int16_t x)
{
    return x;
}
static inline float sitofp_i32_f32(int32_t x)
{
    return x;
}
static inline float sitofp_i64_f32(int64_t x)
{
    return x;
}
static inline float uitofp_i8_f32(uint8_t x)
{
    return x;
}
static inline float uitofp_i16_f32(uint16_t x)
{
    return x;
}
static inline float uitofp_i32_f32(uint32_t x)
{
    return x;
}
static inline float uitofp_i64_f32(uint64_t x)
{
    return x;
}
static inline int8_t fptosi_f32_i8(float x)
{
    return x;
}
static inline int16_t fptosi_f32_i16(float x)
{
    return x;
}
static inline int32_t fptosi_f32_i32(float x)
{
    return x;
}
static inline int64_t fptosi_f32_i64(float x)
{
    return x;
}
static inline uint8_t fptoui_f32_i8(float x)
{
    return x;
}
static inline uint16_t fptoui_f32_i16(float x)
{
    return x;
}
static inline uint32_t fptoui_f32_i32(float x)
{
    return x;
}
static inline uint64_t fptoui_f32_i64(float x)
{
    return x;
}
static inline double fdiv64(double x, double y)
{
    return x / y;
}
static inline double fadd64(double x, double y)
{
    return x + y;
}
static inline double fsub64(double x, double y)
{
    return x - y;
}
static inline double fmul64(double x, double y)
{
    return x * y;
}
static inline double fmin64(double x, double y)
{
    return x < y ? x : y;
}
static inline double fmax64(double x, double y)
{
    return x < y ? y : x;
}
static inline double fpow64(double x, double y)
{
    return pow(x, y);
}
static inline char cmplt64(double x, double y)
{
    return x < y;
}
static inline char cmple64(double x, double y)
{
    return x <= y;
}
static inline double sitofp_i8_f64(int8_t x)
{
    return x;
}
static inline double sitofp_i16_f64(int16_t x)
{
    return x;
}
static inline double sitofp_i32_f64(int32_t x)
{
    return x;
}
static inline double sitofp_i64_f64(int64_t x)
{
    return x;
}
static inline double uitofp_i8_f64(uint8_t x)
{
    return x;
}
static inline double uitofp_i16_f64(uint16_t x)
{
    return x;
}
static inline double uitofp_i32_f64(uint32_t x)
{
    return x;
}
static inline double uitofp_i64_f64(uint64_t x)
{
    return x;
}
static inline int8_t fptosi_f64_i8(double x)
{
    return x;
}
static inline int16_t fptosi_f64_i16(double x)
{
    return x;
}
static inline int32_t fptosi_f64_i32(double x)
{
    return x;
}
static inline int64_t fptosi_f64_i64(double x)
{
    return x;
}
static inline uint8_t fptoui_f64_i8(double x)
{
    return x;
}
static inline uint16_t fptoui_f64_i16(double x)
{
    return x;
}
static inline uint32_t fptoui_f64_i32(double x)
{
    return x;
}
static inline uint64_t fptoui_f64_i64(double x)
{
    return x;
}
static inline float fpconv_f32_f32(float x)
{
    return x;
}
static inline double fpconv_f32_f64(float x)
{
    return x;
}
static inline float fpconv_f64_f32(double x)
{
    return x;
}
static inline double fpconv_f64_f64(double x)
{
    return x;
}
static inline float futrts_log32(float x)
{
    return log(x);
}
static inline float futrts_log2_32(float x)
{
    return log2(x);
}
static inline float futrts_log10_32(float x)
{
    return log10(x);
}
static inline float futrts_sqrt32(float x)
{
    return sqrt(x);
}
static inline float futrts_exp32(float x)
{
    return exp(x);
}
static inline float futrts_cos32(float x)
{
    return cos(x);
}
static inline float futrts_sin32(float x)
{
    return sin(x);
}
static inline float futrts_tan32(float x)
{
    return tan(x);
}
static inline float futrts_acos32(float x)
{
    return acos(x);
}
static inline float futrts_asin32(float x)
{
    return asin(x);
}
static inline float futrts_atan32(float x)
{
    return atan(x);
}
static inline float futrts_atan2_32(float x, float y)
{
    return atan2(x, y);
}
static inline float futrts_gamma32(float x)
{
    return tgamma(x);
}
static inline float futrts_lgamma32(float x)
{
    return lgamma(x);
}
static inline float futrts_round32(float x)
{
    return rint(x);
}
static inline char futrts_isnan32(float x)
{
    return isnan(x);
}
static inline char futrts_isinf32(float x)
{
    return isinf(x);
}
static inline int32_t futrts_to_bits32(float x)
{
    union {
        float f;
        int32_t t;
    } p;
    
    p.f = x;
    return p.t;
}
static inline float futrts_from_bits32(int32_t x)
{
    union {
        int32_t f;
        float t;
    } p;
    
    p.f = x;
    return p.t;
}
static inline double futrts_log64(double x)
{
    return log(x);
}
static inline double futrts_log2_64(double x)
{
    return log2(x);
}
static inline double futrts_log10_64(double x)
{
    return log10(x);
}
static inline double futrts_sqrt64(double x)
{
    return sqrt(x);
}
static inline double futrts_exp64(double x)
{
    return exp(x);
}
static inline double futrts_cos64(double x)
{
    return cos(x);
}
static inline double futrts_sin64(double x)
{
    return sin(x);
}
static inline double futrts_tan64(double x)
{
    return tan(x);
}
static inline double futrts_acos64(double x)
{
    return acos(x);
}
static inline double futrts_asin64(double x)
{
    return asin(x);
}
static inline double futrts_atan64(double x)
{
    return atan(x);
}
static inline double futrts_atan2_64(double x, double y)
{
    return atan2(x, y);
}
static inline double futrts_gamma64(double x)
{
    return tgamma(x);
}
static inline double futrts_lgamma64(double x)
{
    return lgamma(x);
}
static inline double futrts_round64(double x)
{
    return rint(x);
}
static inline char futrts_isnan64(double x)
{
    return isnan(x);
}
static inline char futrts_isinf64(double x)
{
    return isinf(x);
}
static inline int64_t futrts_to_bits64(double x)
{
    union {
        double f;
        int64_t t;
    } p;
    
    p.f = x;
    return p.t;
}
static inline double futrts_from_bits64(int64_t x)
{
    union {
        int64_t f;
        double t;
    } p;
    
    p.f = x;
    return p.t;
}
static int futrts_rev_gmm_objective(struct futhark_context *ctx,
                                    struct memblock *out_mem_p_69641,
                                    int32_t *out_out_arrsizze_69642,
                                    struct memblock *out_mem_p_69643,
                                    int32_t *out_out_arrsizze_69644,
                                    int32_t *out_out_arrsizze_69645,
                                    struct memblock *out_mem_p_69646,
                                    int32_t *out_out_arrsizze_69647,
                                    int32_t *out_out_arrsizze_69648,
                                    struct memblock *out_mem_p_69649,
                                    int32_t *out_out_arrsizze_69650,
                                    int32_t *out_out_arrsizze_69651,
                                    struct memblock x_mem_69258,
                                    struct memblock alphas_mem_69259,
                                    struct memblock means_mem_69260,
                                    struct memblock qs_mem_69261,
                                    struct memblock icf_mem_69262,
                                    int32_t N_68495, int32_t D_68496,
                                    int32_t K_68497, int32_t K_68498,
                                    int32_t D_68499, int32_t K_68500,
                                    int32_t D_68501, int32_t K_68502,
                                    int32_t triD_68503,
                                    double wishart_gamma_68509,
                                    int32_t wishart_m_68510, double d_r_68511)
{
    struct memblock out_mem_69579;
    
    out_mem_69579.references = NULL;
    
    int32_t out_arrsizze_69580;
    struct memblock out_mem_69581;
    
    out_mem_69581.references = NULL;
    
    int32_t out_arrsizze_69582;
    int32_t out_arrsizze_69583;
    struct memblock out_mem_69584;
    
    out_mem_69584.references = NULL;
    
    int32_t out_arrsizze_69585;
    int32_t out_arrsizze_69586;
    struct memblock out_mem_69587;
    
    out_mem_69587.references = NULL;
    
    int32_t out_arrsizze_69588;
    int32_t out_arrsizze_69589;
    int32_t y_68512 = smax32(D_68496, D_68501);
    int32_t D_68513 = smax32(D_68499, y_68512);
    bool dim_zzero_68514 = 0 == N_68495;
    bool dim_zzero_68515 = 0 == D_68496;
    bool old_empty_68516 = dim_zzero_68514 || dim_zzero_68515;
    bool dim_zzero_68517 = 0 == D_68513;
    bool new_empty_68518 = dim_zzero_68514 || dim_zzero_68517;
    bool both_empty_68519 = old_empty_68516 && new_empty_68518;
    bool dim_match_68520 = D_68513 == D_68496;
    bool empty_or_match_68521 = both_empty_68519 || dim_match_68520;
    bool empty_or_match_cert_68522;
    
    if (!empty_or_match_68521) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:11:1-19:14",
                               "function arguments of wrong shape");
        if (memblock_unref(ctx, &out_mem_69587, "out_mem_69587") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69584, "out_mem_69584") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69581, "out_mem_69581") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69579, "out_mem_69579") != 0)
            return 1;
        return 1;
    }
    
    bool dim_zzero_68523 = 0 == K_68498;
    bool dim_zzero_68524 = 0 == D_68499;
    bool old_empty_68525 = dim_zzero_68523 || dim_zzero_68524;
    bool dim_zzero_68526 = 0 == K_68497;
    bool new_empty_68527 = dim_zzero_68517 || dim_zzero_68526;
    bool both_empty_68528 = old_empty_68525 && new_empty_68527;
    bool dim_match_68529 = K_68497 == K_68498;
    bool dim_match_68530 = D_68513 == D_68499;
    bool match_68531 = dim_match_68529 && dim_match_68530;
    bool empty_or_match_68532 = both_empty_68528 || match_68531;
    bool empty_or_match_cert_68533;
    
    if (!empty_or_match_68532) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:11:1-19:14",
                               "function arguments of wrong shape");
        if (memblock_unref(ctx, &out_mem_69587, "out_mem_69587") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69584, "out_mem_69584") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69581, "out_mem_69581") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69579, "out_mem_69579") != 0)
            return 1;
        return 1;
    }
    
    bool dim_zzero_68534 = 0 == K_68500;
    bool dim_zzero_68535 = 0 == D_68501;
    bool old_empty_68536 = dim_zzero_68534 || dim_zzero_68535;
    bool both_empty_68537 = new_empty_68527 && old_empty_68536;
    bool dim_match_68538 = K_68497 == K_68500;
    bool dim_match_68539 = D_68513 == D_68501;
    bool match_68540 = dim_match_68538 && dim_match_68539;
    bool empty_or_match_68541 = both_empty_68537 || match_68540;
    bool empty_or_match_cert_68542;
    
    if (!empty_or_match_68541) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:11:1-19:14",
                               "function arguments of wrong shape");
        if (memblock_unref(ctx, &out_mem_69587, "out_mem_69587") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69584, "out_mem_69584") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69581, "out_mem_69581") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69579, "out_mem_69579") != 0)
            return 1;
        return 1;
    }
    
    bool dim_zzero_68543 = 0 == K_68502;
    bool dim_zzero_68544 = 0 == triD_68503;
    bool old_empty_68545 = dim_zzero_68543 || dim_zzero_68544;
    bool new_empty_68546 = dim_zzero_68526 || dim_zzero_68544;
    bool both_empty_68547 = old_empty_68545 && new_empty_68546;
    bool dim_match_68548 = K_68497 == K_68502;
    bool empty_or_match_68549 = both_empty_68547 || dim_match_68548;
    bool empty_or_match_cert_68550;
    
    if (!empty_or_match_68549) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:11:1-19:14",
                               "function arguments of wrong shape");
        if (memblock_unref(ctx, &out_mem_69587, "out_mem_69587") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69584, "out_mem_69584") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69581, "out_mem_69581") != 0)
            return 1;
        if (memblock_unref(ctx, &out_mem_69579, "out_mem_69579") != 0)
            return 1;
        return 1;
    }
    
    int64_t binop_x_69264 = sext_i32_i64(N_68495);
    int64_t binop_y_69265 = sext_i32_i64(K_68497);
    int64_t binop_x_69266 = binop_x_69264 * binop_y_69265;
    int64_t bytes_69263 = 8 * binop_x_69266;
    struct memblock mem_69267;
    
    mem_69267.references = NULL;
    if (memblock_alloc(ctx, &mem_69267, bytes_69263, "mem_69267"))
        return 1;
    
    int64_t binop_y_69272 = sext_i32_i64(D_68513);
    int64_t binop_x_69273 = binop_x_69266 * binop_y_69272;
    int64_t bytes_69268 = 8 * binop_x_69273;
    struct memblock mem_69274;
    
    mem_69274.references = NULL;
    if (memblock_alloc(ctx, &mem_69274, bytes_69268, "mem_69274"))
        return 1;
    
    struct memblock mem_69281;
    
    mem_69281.references = NULL;
    if (memblock_alloc(ctx, &mem_69281, bytes_69268, "mem_69281"))
        return 1;
    
    int64_t binop_y_69286 = sext_i32_i64(triD_68503);
    int64_t binop_x_69287 = binop_x_69266 * binop_y_69286;
    int64_t bytes_69282 = 8 * binop_x_69287;
    struct memblock mem_69288;
    
    mem_69288.references = NULL;
    if (memblock_alloc(ctx, &mem_69288, bytes_69282, "mem_69288"))
        return 1;
    
    int64_t bytes_69293 = 8 * binop_y_69265;
    struct memblock mem_69295;
    
    mem_69295.references = NULL;
    if (memblock_alloc(ctx, &mem_69295, bytes_69293, "mem_69295"))
        return 1;
    
    int64_t bytes_69297 = 8 * binop_y_69272;
    struct memblock mem_69299;
    
    mem_69299.references = NULL;
    if (memblock_alloc(ctx, &mem_69299, bytes_69297, "mem_69299"))
        return 1;
    
    struct memblock mem_69327;
    
    mem_69327.references = NULL;
    if (memblock_alloc(ctx, &mem_69327, bytes_69297, "mem_69327"))
        return 1;
    
    int64_t binop_x_69331 = binop_y_69272 * binop_y_69272;
    int64_t bytes_69328 = 8 * binop_x_69331;
    struct memblock mem_69332;
    
    mem_69332.references = NULL;
    if (memblock_alloc(ctx, &mem_69332, bytes_69328, "mem_69332"))
        return 1;
    
    struct memblock mem_69347;
    
    mem_69347.references = NULL;
    if (memblock_alloc(ctx, &mem_69347, bytes_69297, "mem_69347"))
        return 1;
    
    struct memblock mem_69354;
    
    mem_69354.references = NULL;
    if (memblock_alloc(ctx, &mem_69354, bytes_69328, "mem_69354"))
        return 1;
    
    int64_t binop_x_69358 = binop_y_69272 * binop_y_69286;
    int64_t bytes_69355 = 8 * binop_x_69358;
    struct memblock mem_69359;
    
    mem_69359.references = NULL;
    if (memblock_alloc(ctx, &mem_69359, bytes_69355, "mem_69359"))
        return 1;
    
    struct memblock mem_69362;
    
    mem_69362.references = NULL;
    if (memblock_alloc(ctx, &mem_69362, bytes_69297, "mem_69362"))
        return 1;
    
    struct memblock mem_69370;
    
    mem_69370.references = NULL;
    if (memblock_alloc(ctx, &mem_69370, bytes_69328, "mem_69370"))
        return 1;
    
    struct memblock mem_69375;
    
    mem_69375.references = NULL;
    if (memblock_alloc(ctx, &mem_69375, bytes_69355, "mem_69375"))
        return 1;
    
    int64_t bytes_69381 = 8 * binop_y_69286;
    
    for (int32_t i_69016 = 0; i_69016 < N_68495; i_69016++) {
        double res_68618;
        double redout_68923 = 0.0;
        
        for (int32_t i_68925 = 0; i_68925 < K_68497; i_68925++) {
            double alphas_elem_68623 =
                   *(double *) &alphas_mem_69259.mem[i_68925 * 8];
            double res_68628;
            double redout_68912 = 0.0;
            
            for (int32_t i_68913 = 0; i_68913 < D_68513; i_68913++) {
                double x_68632 = *(double *) &qs_mem_69261.mem[(i_68925 *
                                                                D_68501 +
                                                                i_68913) * 8];
                double res_68631 = x_68632 + redout_68912;
                double redout_tmp_69596 = res_68631;
                
                redout_68912 = redout_tmp_69596;
            }
            res_68628 = redout_68912;
            
            double x_68633 = alphas_elem_68623 + res_68628;
            
            for (int32_t i_68916 = 0; i_68916 < D_68513; i_68916++) {
                double x_elem_elem_68637 =
                       *(double *) &x_mem_69258.mem[(i_69016 * D_68496 +
                                                     i_68916) * 8];
                double means_elem_elem_68638 =
                       *(double *) &means_mem_69260.mem[(i_68925 * D_68499 +
                                                         i_68916) * 8];
                double res_68639 = x_elem_elem_68637 - means_elem_elem_68638;
                
                *(double *) &mem_69299.mem[i_68916 * 8] = res_68639;
            }
            
            double res_68640;
            double redout_68920 = 0.0;
            
            for (int32_t i_68921 = 0; i_68921 < D_68513; i_68921++) {
                double qs_elem_elem_68645 =
                       *(double *) &qs_mem_69261.mem[(i_68925 * D_68501 +
                                                      i_68921) * 8];
                double res_68646;
                double redout_68918 = 0.0;
                
                for (int32_t i_68919 = 0; i_68919 < D_68513; i_68919++) {
                    double x_68651 = *(double *) &mem_69299.mem[i_68919 * 8];
                    bool cond_68652 = slt32(i_68921, i_68919);
                    double res_68653;
                    
                    if (cond_68652) {
                        res_68653 = 0.0;
                    } else {
                        bool cond_68654 = i_68921 == i_68919;
                        double res_68655;
                        
                        if (cond_68654) {
                            double res_68656;
                            
                            res_68656 = futrts_exp64(qs_elem_elem_68645);
                            res_68655 = res_68656;
                        } else {
                            int32_t y_68657 = D_68513 - 1;
                            int32_t x_68658 = D_68513 * y_68657;
                            int32_t res_68659 = sdiv32(x_68658, 2);
                            int32_t gmm_knossos_tri_arg_68660 = D_68513 -
                                    i_68919;
                            int32_t y_68661 = gmm_knossos_tri_arg_68660 - 1;
                            int32_t x_68662 = gmm_knossos_tri_arg_68660 *
                                    y_68661;
                            int32_t res_68663 = sdiv32(x_68662, 2);
                            int32_t x_68664 = res_68659 - res_68663;
                            int32_t x_68665 = i_68921 - i_68919;
                            int32_t y_68666 = x_68665 - 1;
                            int32_t i_68667 = x_68664 + y_68666;
                            double res_68668 =
                                   *(double *) &icf_mem_69262.mem[(i_68925 *
                                                                   triD_68503 +
                                                                   i_68667) *
                                                                  8];
                            
                            res_68655 = res_68668;
                        }
                        res_68653 = res_68655;
                    }
                    
                    double res_68669 = x_68651 * res_68653;
                    double res_68649 = res_68669 + redout_68918;
                    double redout_tmp_69599 = res_68649;
                    
                    redout_68918 = redout_tmp_69599;
                }
                res_68646 = redout_68918;
                
                double res_68670 = res_68646 * res_68646;
                double res_68643 = res_68670 + redout_68920;
                double redout_tmp_69598 = res_68643;
                
                redout_68920 = redout_tmp_69598;
            }
            res_68640 = redout_68920;
            
            double y_68671 = 0.5 * res_68640;
            double res_68672 = x_68633 - y_68671;
            double res_68673;
            
            res_68673 = futrts_exp64(res_68672);
            
            double res_68622 = res_68673 + redout_68923;
            
            *(double *) &mem_69295.mem[i_68925 * 8] = res_68672;
            
            double redout_tmp_69594 = res_68622;
            
            redout_68923 = redout_tmp_69594;
        }
        res_68618 = redout_68923;
        
        double x_68676 = 1.0 / res_68618;
        double res_68677 = d_r_68511 * x_68676;
        
        for (int32_t i_69003 = 0; i_69003 < K_68497; i_69003++) {
            double res_elem_68683 = *(double *) &mem_69295.mem[i_69003 * 8];
            double res_68687;
            
            res_68687 = futrts_exp64(res_elem_68683);
            
            double res_68688 = res_68677 * res_68687;
            
            for (int32_t i_68935 = 0; i_68935 < D_68513; i_68935++) {
                double qs_elem_elem_68694 =
                       *(double *) &qs_mem_69261.mem[(i_69003 * D_68501 +
                                                      i_68935) * 8];
                double x_elem_elem_68695 =
                       *(double *) &x_mem_69258.mem[(i_69016 * D_68496 +
                                                     i_68935) * 8];
                double means_elem_elem_68696 =
                       *(double *) &means_mem_69260.mem[(i_69003 * D_68499 +
                                                         i_68935) * 8];
                
                for (int32_t i_68929 = 0; i_68929 < D_68513; i_68929++) {
                    bool cond_68699 = slt32(i_68935, i_68929);
                    double res_68700;
                    
                    if (cond_68699) {
                        res_68700 = 0.0;
                    } else {
                        bool cond_68701 = i_68935 == i_68929;
                        double res_68702;
                        
                        if (cond_68701) {
                            double res_68703;
                            
                            res_68703 = futrts_exp64(qs_elem_elem_68694);
                            res_68702 = res_68703;
                        } else {
                            int32_t y_68704 = D_68513 - 1;
                            int32_t x_68705 = D_68513 * y_68704;
                            int32_t res_68706 = sdiv32(x_68705, 2);
                            int32_t gmm_knossos_tri_arg_68707 = D_68513 -
                                    i_68929;
                            int32_t y_68708 = gmm_knossos_tri_arg_68707 - 1;
                            int32_t x_68709 = gmm_knossos_tri_arg_68707 *
                                    y_68708;
                            int32_t res_68710 = sdiv32(x_68709, 2);
                            int32_t x_68711 = res_68706 - res_68710;
                            int32_t x_68712 = i_68935 - i_68929;
                            int32_t y_68713 = x_68712 - 1;
                            int32_t i_68714 = x_68711 + y_68713;
                            double res_68715 =
                                   *(double *) &icf_mem_69262.mem[(i_69003 *
                                                                   triD_68503 +
                                                                   i_68714) *
                                                                  8];
                            
                            res_68702 = res_68715;
                        }
                        res_68700 = res_68702;
                    }
                    *(double *) &mem_69332.mem[(i_68935 * D_68513 + i_68929) *
                                               8] = res_68700;
                }
                
                double res_68716 = x_elem_elem_68695 - means_elem_elem_68696;
                
                *(double *) &mem_69327.mem[i_68935 * 8] = res_68716;
            }
            
            double y_68717 = 0.0 - res_68688;
            double rev_sqnorm_arg_68718 = 0.5 * y_68717;
            
            for (int32_t i_68942 = 0; i_68942 < D_68513; i_68942++) {
                double res_68721;
                double redout_68938 = 0.0;
                
                for (int32_t i_68939 = 0; i_68939 < D_68513; i_68939++) {
                    double x_68725 = *(double *) &mem_69327.mem[i_68939 * 8];
                    double x_68726 = *(double *) &mem_69332.mem[(i_68942 *
                                                                 D_68513 +
                                                                 i_68939) * 8];
                    double res_68727 = x_68725 * x_68726;
                    double res_68724 = res_68727 + redout_68938;
                    double redout_tmp_69608 = res_68724;
                    
                    redout_68938 = redout_tmp_69608;
                }
                res_68721 = redout_68938;
                
                double res_68728 = rev_sqnorm_arg_68718 * res_68721;
                double res_68729 = res_68728 + res_68728;
                
                *(double *) &mem_69347.mem[i_68942 * 8] = res_68729;
            }
            for (int32_t i_68979 = 0; i_68979 < D_68513; i_68979++) {
                double x_68734 = *(double *) &mem_69347.mem[i_68979 * 8];
                double qs_elem_elem_68737 =
                       *(double *) &qs_mem_69261.mem[(i_69003 * D_68501 +
                                                      i_68979) * 8];
                double res_68738;
                double redout_68944 = 0.0;
                
                for (int32_t i_68945 = 0; i_68945 < D_68513; i_68945++) {
                    double x_68742 = *(double *) &mem_69332.mem[(i_68945 *
                                                                 D_68513 +
                                                                 i_68979) * 8];
                    double x_68743 = *(double *) &mem_69347.mem[i_68945 * 8];
                    double res_68744 = x_68742 * x_68743;
                    double res_68741 = res_68744 + redout_68944;
                    double redout_tmp_69612 = res_68741;
                    
                    redout_68944 = redout_tmp_69612;
                }
                res_68738 = redout_68944;
                
                double res_68745 = 0.0 - res_68738;
                
                for (int32_t i_68958 = 0; i_68958 < D_68513; i_68958++) {
                    double x_68754 = *(double *) &mem_69327.mem[i_68958 * 8];
                    double res_68756 = x_68734 * x_68754;
                    bool cond_68757 = slt32(i_68979, i_68958);
                    bool cond_68758 = i_68979 == i_68958;
                    struct memblock res_mem_69402;
                    
                    res_mem_69402.references = NULL;
                    
                    struct memblock res_mem_69403;
                    
                    res_mem_69403.references = NULL;
                    if (cond_68757) {
                        struct memblock mem_69380;
                        
                        mem_69380.references = NULL;
                        if (memblock_alloc(ctx, &mem_69380, bytes_69297,
                                           "mem_69380"))
                            return 1;
                        for (int32_t i_69615 = 0; i_69615 < D_68513;
                             i_69615++) {
                            *(double *) &mem_69380.mem[i_69615 * 8] = 0.0;
                        }
                        
                        struct memblock mem_69383;
                        
                        mem_69383.references = NULL;
                        if (memblock_alloc(ctx, &mem_69383, bytes_69381,
                                           "mem_69383"))
                            return 1;
                        for (int32_t i_69616 = 0; i_69616 < triD_68503;
                             i_69616++) {
                            *(double *) &mem_69383.mem[i_69616 * 8] = 0.0;
                        }
                        if (memblock_set(ctx, &res_mem_69402, &mem_69380,
                                         "mem_69380") != 0)
                            return 1;
                        if (memblock_set(ctx, &res_mem_69403, &mem_69383,
                                         "mem_69383") != 0)
                            return 1;
                        if (memblock_unref(ctx, &mem_69383, "mem_69383") != 0)
                            return 1;
                        if (memblock_unref(ctx, &mem_69380, "mem_69380") != 0)
                            return 1;
                    } else {
                        struct memblock res_mem_69400;
                        
                        res_mem_69400.references = NULL;
                        
                        struct memblock res_mem_69401;
                        
                        res_mem_69401.references = NULL;
                        if (cond_68758) {
                            double res_68769;
                            
                            res_68769 = futrts_exp64(qs_elem_elem_68737);
                            
                            double deltaVec_arg_68770 = res_68756 * res_68769;
                            struct memblock mem_69386;
                            
                            mem_69386.references = NULL;
                            if (memblock_alloc(ctx, &mem_69386, bytes_69297,
                                               "mem_69386"))
                                return 1;
                            for (int32_t i_68948 = 0; i_68948 < D_68513;
                                 i_68948++) {
                                bool cond_68774 = i_68948 == i_68979;
                                double res_68775;
                                
                                if (cond_68774) {
                                    res_68775 = deltaVec_arg_68770;
                                } else {
                                    res_68775 = 0.0;
                                }
                                *(double *) &mem_69386.mem[i_68948 * 8] =
                                    res_68775;
                            }
                            
                            struct memblock mem_69391;
                            
                            mem_69391.references = NULL;
                            if (memblock_alloc(ctx, &mem_69391, bytes_69381,
                                               "mem_69391"))
                                return 1;
                            for (int32_t i_69618 = 0; i_69618 < triD_68503;
                                 i_69618++) {
                                *(double *) &mem_69391.mem[i_69618 * 8] = 0.0;
                            }
                            if (memblock_set(ctx, &res_mem_69400, &mem_69386,
                                             "mem_69386") != 0)
                                return 1;
                            if (memblock_set(ctx, &res_mem_69401, &mem_69391,
                                             "mem_69391") != 0)
                                return 1;
                            if (memblock_unref(ctx, &mem_69391, "mem_69391") !=
                                0)
                                return 1;
                            if (memblock_unref(ctx, &mem_69386, "mem_69386") !=
                                0)
                                return 1;
                        } else {
                            int32_t y_68778 = i_68979 - 1;
                            int32_t x_68779 = y_68778 * i_68979;
                            int32_t res_68780 = sdiv32(x_68779, 2);
                            int32_t deltaVec_arg_68781 = res_68780 + i_68958;
                            struct memblock mem_69394;
                            
                            mem_69394.references = NULL;
                            if (memblock_alloc(ctx, &mem_69394, bytes_69381,
                                               "mem_69394"))
                                return 1;
                            for (int32_t i_68952 = 0; i_68952 < triD_68503;
                                 i_68952++) {
                                bool cond_68785 = i_68952 == deltaVec_arg_68781;
                                double res_68786;
                                
                                if (cond_68785) {
                                    res_68786 = res_68756;
                                } else {
                                    res_68786 = 0.0;
                                }
                                *(double *) &mem_69394.mem[i_68952 * 8] =
                                    res_68786;
                            }
                            
                            struct memblock mem_69399;
                            
                            mem_69399.references = NULL;
                            if (memblock_alloc(ctx, &mem_69399, bytes_69297,
                                               "mem_69399"))
                                return 1;
                            for (int32_t i_69620 = 0; i_69620 < D_68513;
                                 i_69620++) {
                                *(double *) &mem_69399.mem[i_69620 * 8] = 0.0;
                            }
                            if (memblock_set(ctx, &res_mem_69400, &mem_69399,
                                             "mem_69399") != 0)
                                return 1;
                            if (memblock_set(ctx, &res_mem_69401, &mem_69394,
                                             "mem_69394") != 0)
                                return 1;
                            if (memblock_unref(ctx, &mem_69399, "mem_69399") !=
                                0)
                                return 1;
                            if (memblock_unref(ctx, &mem_69394, "mem_69394") !=
                                0)
                                return 1;
                        }
                        if (memblock_set(ctx, &res_mem_69402, &res_mem_69400,
                                         "res_mem_69400") != 0)
                            return 1;
                        if (memblock_set(ctx, &res_mem_69403, &res_mem_69401,
                                         "res_mem_69401") != 0)
                            return 1;
                        if (memblock_unref(ctx, &res_mem_69401,
                                           "res_mem_69401") != 0)
                            return 1;
                        if (memblock_unref(ctx, &res_mem_69400,
                                           "res_mem_69400") != 0)
                            return 1;
                    }
                    memmove(mem_69370.mem + i_68958 * D_68513 * 8,
                            res_mem_69402.mem + 0, D_68513 * sizeof(double));
                    if (memblock_unref(ctx, &res_mem_69402, "res_mem_69402") !=
                        0)
                        return 1;
                    memmove(mem_69375.mem + i_68958 * triD_68503 * 8,
                            res_mem_69403.mem + 0, triD_68503 * sizeof(double));
                    if (memblock_unref(ctx, &res_mem_69403, "res_mem_69403") !=
                        0)
                        return 1;
                    if (memblock_unref(ctx, &res_mem_69403, "res_mem_69403") !=
                        0)
                        return 1;
                    if (memblock_unref(ctx, &res_mem_69402, "res_mem_69402") !=
                        0)
                        return 1;
                }
                for (int32_t i_68965 = 0; i_68965 < D_68513; i_68965++) {
                    double res_68796;
                    double redout_68961 = 0.0;
                    
                    for (int32_t i_68962 = 0; i_68962 < D_68513; i_68962++) {
                        double x_68800 = *(double *) &mem_69370.mem[(i_68962 *
                                                                     D_68513 +
                                                                     i_68965) *
                                                                    8];
                        double res_68799 = x_68800 + redout_68961;
                        double redout_tmp_69622 = res_68799;
                        
                        redout_68961 = redout_tmp_69622;
                    }
                    res_68796 = redout_68961;
                    *(double *) &mem_69354.mem[(i_68979 * D_68513 + i_68965) *
                                               8] = res_68796;
                }
                for (int32_t i_68971 = 0; i_68971 < triD_68503; i_68971++) {
                    double res_68804;
                    double redout_68967 = 0.0;
                    
                    for (int32_t i_68968 = 0; i_68968 < D_68513; i_68968++) {
                        double x_68808 = *(double *) &mem_69375.mem[(i_68968 *
                                                                     triD_68503 +
                                                                     i_68971) *
                                                                    8];
                        double res_68807 = x_68808 + redout_68967;
                        double redout_tmp_69624 = res_68807;
                        
                        redout_68967 = redout_tmp_69624;
                    }
                    res_68804 = redout_68967;
                    *(double *) &mem_69359.mem[(i_68979 * triD_68503 +
                                                i_68971) * 8] = res_68804;
                }
                *(double *) &mem_69362.mem[i_68979 * 8] = res_68745;
            }
            memmove(mem_69274.mem + (i_69016 * (D_68513 * K_68497) + i_69003 *
                                     D_68513) * 8, mem_69362.mem + 0, D_68513 *
                    sizeof(double));
            for (int32_t i_68987 = 0; i_68987 < triD_68503; i_68987++) {
                double res_68814;
                double redout_68983 = 0.0;
                
                for (int32_t i_68984 = 0; i_68984 < D_68513; i_68984++) {
                    double x_68818 = *(double *) &mem_69359.mem[(i_68984 *
                                                                 triD_68503 +
                                                                 i_68987) * 8];
                    double res_68817 = x_68818 + redout_68983;
                    double redout_tmp_69626 = res_68817;
                    
                    redout_68983 = redout_tmp_69626;
                }
                res_68814 = redout_68983;
                *(double *) &mem_69288.mem[(i_69016 * (triD_68503 * K_68497) +
                                            i_69003 * triD_68503 + i_68987) *
                                           8] = res_68814;
            }
            for (int32_t i_68993 = 0; i_68993 < D_68513; i_68993++) {
                double res_68823;
                double redout_68989 = 0.0;
                
                for (int32_t i_68990 = 0; i_68990 < D_68513; i_68990++) {
                    double x_68827 = *(double *) &mem_69354.mem[(i_68990 *
                                                                 D_68513 +
                                                                 i_68993) * 8];
                    double res_68826 = x_68827 + redout_68989;
                    double redout_tmp_69628 = res_68826;
                    
                    redout_68989 = redout_tmp_69628;
                }
                res_68823 = redout_68989;
                
                double res_68828 = res_68688 + res_68823;
                
                *(double *) &mem_69281.mem[(i_69016 * (D_68513 * K_68497) +
                                            i_69003 * D_68513 + i_68993) * 8] =
                    res_68828;
            }
            *(double *) &mem_69267.mem[(i_69016 * K_68497 + i_69003) * 8] =
                res_68688;
        }
    }
    if (memblock_unref(ctx, &mem_69295, "mem_69295") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69299, "mem_69299") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69327, "mem_69327") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69332, "mem_69332") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69347, "mem_69347") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69354, "mem_69354") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69359, "mem_69359") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69362, "mem_69362") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69370, "mem_69370") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69375, "mem_69375") != 0)
        return 1;
    
    double res_68829 = sitofp_i32_f64(N_68495);
    double y_68830 = 0.0 - d_r_68511;
    double rev_logsumexp_arg_68831 = res_68829 * y_68830;
    int64_t binop_x_69480 = binop_y_69265 * binop_y_69272;
    int64_t bytes_69477 = 8 * binop_x_69480;
    struct memblock mem_69481;
    
    mem_69481.references = NULL;
    if (memblock_alloc(ctx, &mem_69481, bytes_69477, "mem_69481"))
        return 1;
    
    double res_68833;
    double redout_69028 = 0.0;
    
    for (int32_t i_69030 = 0; i_69030 < K_68497; i_69030++) {
        double alphas_elem_68839 = *(double *) &alphas_mem_69259.mem[i_69030 *
                                                                     8];
        
        for (int32_t i_69025 = 0; i_69025 < D_68513; i_69025++) {
            double res_68842;
            double redout_69021 = 0.0;
            
            for (int32_t i_69022 = 0; i_69022 < N_68495; i_69022++) {
                double x_68846 = *(double *) &mem_69274.mem[(i_69022 *
                                                             (D_68513 *
                                                              K_68497) +
                                                             i_69030 * D_68513 +
                                                             i_69025) * 8];
                double res_68845 = x_68846 + redout_69021;
                double redout_tmp_69632 = res_68845;
                
                redout_69021 = redout_tmp_69632;
            }
            res_68842 = redout_69021;
            *(double *) &mem_69481.mem[(i_69030 * D_68513 + i_69025) * 8] =
                res_68842;
        }
        
        double res_68847;
        
        res_68847 = futrts_exp64(alphas_elem_68839);
        
        double res_68837 = res_68847 + redout_69028;
        double redout_tmp_69629 = res_68837;
        
        redout_69028 = redout_tmp_69629;
    }
    res_68833 = redout_69028;
    if (memblock_unref(ctx, &mem_69274, "mem_69274") != 0)
        return 1;
    
    double x_68848 = 1.0 / res_68833;
    double res_68849 = rev_logsumexp_arg_68831 * x_68848;
    double t1374_68850 = 0.5 * d_r_68511;
    double x_68851 = wishart_gamma_68509 * wishart_gamma_68509;
    double t1389_68852 = t1374_68850 * x_68851;
    double res_68853 = sitofp_i32_f64(wishart_m_68510);
    double res_68854 = y_68830 * res_68853;
    int64_t binop_x_69495 = binop_y_69265 * binop_y_69286;
    int64_t bytes_69492 = 8 * binop_x_69495;
    struct memblock mem_69496;
    
    mem_69496.references = NULL;
    if (memblock_alloc(ctx, &mem_69496, bytes_69492, "mem_69496"))
        return 1;
    
    struct memblock mem_69501;
    
    mem_69501.references = NULL;
    if (memblock_alloc(ctx, &mem_69501, bytes_69477, "mem_69501"))
        return 1;
    
    struct memblock mem_69504;
    
    mem_69504.references = NULL;
    if (memblock_alloc(ctx, &mem_69504, bytes_69293, "mem_69504"))
        return 1;
    for (int32_t i_69052 = 0; i_69052 < K_68497; i_69052++) {
        double alphas_elem_68864 = *(double *) &alphas_mem_69259.mem[i_69052 *
                                                                     8];
        double res_68867;
        double redout_69032 = 0.0;
        
        for (int32_t i_69033 = 0; i_69033 < N_68495; i_69033++) {
            double x_68871 = *(double *) &mem_69267.mem[(i_69033 * K_68497 +
                                                         i_69052) * 8];
            double res_68870 = x_68871 + redout_69032;
            double redout_tmp_69636 = res_68870;
            
            redout_69032 = redout_tmp_69636;
        }
        res_68867 = redout_69032;
        
        double res_68872;
        
        res_68872 = futrts_exp64(alphas_elem_68864);
        
        double res_68873 = res_68849 * res_68872;
        double res_68874 = res_68867 + res_68873;
        
        for (int32_t i_69038 = 0; i_69038 < D_68513; i_69038++) {
            double qs_elem_elem_68878 = *(double *) &qs_mem_69261.mem[(i_69052 *
                                                                       D_68501 +
                                                                       i_69038) *
                                                                      8];
            double res_68880;
            double redout_69034 = 0.0;
            
            for (int32_t i_69035 = 0; i_69035 < N_68495; i_69035++) {
                double x_68884 = *(double *) &mem_69281.mem[(i_69035 *
                                                             (D_68513 *
                                                              K_68497) +
                                                             i_69052 * D_68513 +
                                                             i_69038) * 8];
                double res_68883 = x_68884 + redout_69034;
                double redout_tmp_69638 = res_68883;
                
                redout_69034 = redout_tmp_69638;
            }
            res_68880 = redout_69034;
            
            double res_68885;
            
            res_68885 = futrts_exp64(qs_elem_elem_68878);
            
            double res_68886 = t1389_68852 * res_68885;
            double res_68887 = res_68886 + res_68886;
            double res_68889 = res_68885 * res_68887;
            double res_68890 = res_68854 + res_68889;
            double res_68891 = res_68880 + res_68890;
            
            *(double *) &mem_69501.mem[(i_69052 * D_68513 + i_69038) * 8] =
                res_68891;
        }
        for (int32_t i_69044 = 0; i_69044 < triD_68503; i_69044++) {
            double icf_elem_elem_68894 =
                   *(double *) &icf_mem_69262.mem[(i_69052 * triD_68503 +
                                                   i_69044) * 8];
            double res_68895;
            double redout_69040 = 0.0;
            
            for (int32_t i_69041 = 0; i_69041 < N_68495; i_69041++) {
                double x_68899 = *(double *) &mem_69288.mem[(i_69041 *
                                                             (triD_68503 *
                                                              K_68497) +
                                                             i_69052 *
                                                             triD_68503 +
                                                             i_69044) * 8];
                double res_68898 = x_68899 + redout_69040;
                double redout_tmp_69640 = res_68898;
                
                redout_69040 = redout_tmp_69640;
            }
            res_68895 = redout_69040;
            
            double res_68900 = t1389_68852 * icf_elem_elem_68894;
            double res_68901 = res_68900 + res_68900;
            double res_68902 = res_68895 + res_68901;
            
            *(double *) &mem_69496.mem[(i_69052 * triD_68503 + i_69044) * 8] =
                res_68902;
        }
        *(double *) &mem_69504.mem[i_69052 * 8] = res_68874;
    }
    if (memblock_unref(ctx, &mem_69267, "mem_69267") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69281, "mem_69281") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69288, "mem_69288") != 0)
        return 1;
    out_arrsizze_69580 = K_68497;
    out_arrsizze_69582 = K_68497;
    out_arrsizze_69583 = D_68513;
    out_arrsizze_69585 = K_68497;
    out_arrsizze_69586 = D_68513;
    out_arrsizze_69588 = K_68497;
    out_arrsizze_69589 = triD_68503;
    if (memblock_set(ctx, &out_mem_69579, &mem_69504, "mem_69504") != 0)
        return 1;
    if (memblock_set(ctx, &out_mem_69581, &mem_69481, "mem_69481") != 0)
        return 1;
    if (memblock_set(ctx, &out_mem_69584, &mem_69501, "mem_69501") != 0)
        return 1;
    if (memblock_set(ctx, &out_mem_69587, &mem_69496, "mem_69496") != 0)
        return 1;
    (*out_mem_p_69641).references = NULL;
    if (memblock_set(ctx, &*out_mem_p_69641, &out_mem_69579, "out_mem_69579") !=
        0)
        return 1;
    *out_out_arrsizze_69642 = out_arrsizze_69580;
    (*out_mem_p_69643).references = NULL;
    if (memblock_set(ctx, &*out_mem_p_69643, &out_mem_69581, "out_mem_69581") !=
        0)
        return 1;
    *out_out_arrsizze_69644 = out_arrsizze_69582;
    *out_out_arrsizze_69645 = out_arrsizze_69583;
    (*out_mem_p_69646).references = NULL;
    if (memblock_set(ctx, &*out_mem_p_69646, &out_mem_69584, "out_mem_69584") !=
        0)
        return 1;
    *out_out_arrsizze_69647 = out_arrsizze_69585;
    *out_out_arrsizze_69648 = out_arrsizze_69586;
    (*out_mem_p_69649).references = NULL;
    if (memblock_set(ctx, &*out_mem_p_69649, &out_mem_69587, "out_mem_69587") !=
        0)
        return 1;
    *out_out_arrsizze_69650 = out_arrsizze_69588;
    *out_out_arrsizze_69651 = out_arrsizze_69589;
    if (memblock_unref(ctx, &mem_69504, "mem_69504") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69501, "mem_69501") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69496, "mem_69496") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69481, "mem_69481") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69375, "mem_69375") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69370, "mem_69370") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69362, "mem_69362") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69359, "mem_69359") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69354, "mem_69354") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69347, "mem_69347") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69332, "mem_69332") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69327, "mem_69327") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69299, "mem_69299") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69295, "mem_69295") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69288, "mem_69288") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69281, "mem_69281") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69274, "mem_69274") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69267, "mem_69267") != 0)
        return 1;
    if (memblock_unref(ctx, &out_mem_69587, "out_mem_69587") != 0)
        return 1;
    if (memblock_unref(ctx, &out_mem_69584, "out_mem_69584") != 0)
        return 1;
    if (memblock_unref(ctx, &out_mem_69581, "out_mem_69581") != 0)
        return 1;
    if (memblock_unref(ctx, &out_mem_69579, "out_mem_69579") != 0)
        return 1;
    return 0;
}
static int futrts_gmm_objective(struct futhark_context *ctx,
                                double *out_scalar_out_69652,
                                struct memblock x_mem_69258,
                                struct memblock alphas_mem_69259,
                                struct memblock means_mem_69260,
                                struct memblock qs_mem_69261,
                                struct memblock icf_mem_69262, int32_t N_68236,
                                int32_t D_68237, int32_t K_68238,
                                int32_t K_68239, int32_t D_68240,
                                int32_t K_68241, int32_t D_68242,
                                int32_t K_68243, int32_t triD_68244,
                                double wishart_gamma_68250,
                                int32_t wishart_m_68251)
{
    double scalar_out_69565;
    int32_t y_68252 = smax32(D_68237, D_68242);
    int32_t D_68253 = smax32(D_68240, y_68252);
    bool dim_zzero_68254 = 0 == N_68236;
    bool dim_zzero_68255 = 0 == D_68237;
    bool old_empty_68256 = dim_zzero_68254 || dim_zzero_68255;
    bool dim_zzero_68257 = 0 == D_68253;
    bool new_empty_68258 = dim_zzero_68254 || dim_zzero_68257;
    bool both_empty_68259 = old_empty_68256 && new_empty_68258;
    bool dim_match_68260 = D_68253 == D_68237;
    bool empty_or_match_68261 = both_empty_68259 || dim_match_68260;
    bool empty_or_match_cert_68262;
    
    if (!empty_or_match_68261) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76",
                               "function arguments of wrong shape");
        return 1;
    }
    
    bool dim_zzero_68263 = 0 == K_68239;
    bool dim_zzero_68264 = 0 == D_68240;
    bool old_empty_68265 = dim_zzero_68263 || dim_zzero_68264;
    bool dim_zzero_68266 = 0 == K_68238;
    bool new_empty_68267 = dim_zzero_68257 || dim_zzero_68266;
    bool both_empty_68268 = old_empty_68265 && new_empty_68267;
    bool dim_match_68269 = K_68238 == K_68239;
    bool dim_match_68270 = D_68253 == D_68240;
    bool match_68271 = dim_match_68269 && dim_match_68270;
    bool empty_or_match_68272 = both_empty_68268 || match_68271;
    bool empty_or_match_cert_68273;
    
    if (!empty_or_match_68272) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76",
                               "function arguments of wrong shape");
        return 1;
    }
    
    bool dim_zzero_68274 = 0 == K_68241;
    bool dim_zzero_68275 = 0 == D_68242;
    bool old_empty_68276 = dim_zzero_68274 || dim_zzero_68275;
    bool both_empty_68277 = new_empty_68267 && old_empty_68276;
    bool dim_match_68278 = K_68238 == K_68241;
    bool dim_match_68279 = D_68253 == D_68242;
    bool match_68280 = dim_match_68278 && dim_match_68279;
    bool empty_or_match_68281 = both_empty_68277 || match_68280;
    bool empty_or_match_cert_68282;
    
    if (!empty_or_match_68281) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76",
                               "function arguments of wrong shape");
        return 1;
    }
    
    bool dim_zzero_68283 = 0 == K_68243;
    bool dim_zzero_68284 = 0 == triD_68244;
    bool old_empty_68285 = dim_zzero_68283 || dim_zzero_68284;
    bool new_empty_68286 = dim_zzero_68266 || dim_zzero_68284;
    bool both_empty_68287 = old_empty_68285 && new_empty_68286;
    bool dim_match_68288 = K_68238 == K_68243;
    bool empty_or_match_68289 = both_empty_68287 || dim_match_68288;
    bool empty_or_match_cert_68290;
    
    if (!empty_or_match_68289) {
        ctx->error = msgprintf("Error at %s:\n%s\n",
                               "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76",
                               "function arguments of wrong shape");
        return 1;
    }
    
    int32_t lifted_0_to_float_arg_68291 = N_68236 * D_68253;
    double res_68292 = sitofp_i32_f64(lifted_0_to_float_arg_68291);
    double x_68293 = -0.9189385332046727 * res_68292;
    int64_t binop_x_69264 = sext_i32_i64(K_68238);
    int64_t bytes_69263 = 8 * binop_x_69264;
    struct memblock mem_69265;
    
    mem_69265.references = NULL;
    if (memblock_alloc(ctx, &mem_69265, bytes_69263, "mem_69265"))
        return 1;
    
    int64_t binop_x_69268 = sext_i32_i64(D_68253);
    int64_t bytes_69267 = 8 * binop_x_69268;
    struct memblock mem_69269;
    
    mem_69269.references = NULL;
    if (memblock_alloc(ctx, &mem_69269, bytes_69267, "mem_69269"))
        return 1;
    
    double res_68327;
    double redout_68928 = 0.0;
    
    for (int32_t i_68929 = 0; i_68929 < N_68236; i_68929++) {
        for (int32_t i_68924 = 0; i_68924 < K_68238; i_68924++) {
            double alphas_elem_68903 =
                   *(double *) &alphas_mem_69259.mem[i_68924 * 8];
            double res_68344;
            double redout_68912 = 0.0;
            
            for (int32_t i_68913 = 0; i_68913 < D_68253; i_68913++) {
                double x_68348 = *(double *) &qs_mem_69261.mem[(i_68924 *
                                                                D_68242 +
                                                                i_68913) * 8];
                double res_68347 = x_68348 + redout_68912;
                double redout_tmp_69568 = res_68347;
                
                redout_68912 = redout_tmp_69568;
            }
            res_68344 = redout_68912;
            
            double x_68349 = res_68344 + alphas_elem_68903;
            
            for (int32_t i_68916 = 0; i_68916 < D_68253; i_68916++) {
                bool y_68353 = slt32(i_68916, D_68253);
                bool index_certs_68355;
                
                if (!y_68353) {
                    ctx->error = msgprintf("Error at %s:\n%s%d%s%d%s\n",
                                           "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76 -> tools/KnossosFuthark/gmm_wrapper.fut:9:3-76 -> tools/KnossosFuthark/gmm_knossos.fut:131:57-139:174 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:133:81-139:172 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:138:147-139:168 -> tools/KnossosFuthark/gmm_knossos.fut:46:3-29 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:46:18-21",
                                           "Index [", i_68916,
                                           "] out of bounds for array of shape [",
                                           D_68253, "].");
                    if (memblock_unref(ctx, &mem_69269, "mem_69269") != 0)
                        return 1;
                    if (memblock_unref(ctx, &mem_69265, "mem_69265") != 0)
                        return 1;
                    return 1;
                }
                
                double x_68356 = *(double *) &x_mem_69258.mem[(i_68929 *
                                                               D_68237 +
                                                               i_68916) * 8];
                double y_68357 = *(double *) &means_mem_69260.mem[(i_68924 *
                                                                   D_68240 +
                                                                   i_68916) *
                                                                  8];
                double res_68358 = x_68356 - y_68357;
                
                *(double *) &mem_69269.mem[i_68916 * 8] = res_68358;
            }
            
            double res_68359;
            double redout_68920 = 0.0;
            
            for (int32_t i_68921 = 0; i_68921 < D_68253; i_68921++) {
                double res_68364;
                double redout_68918 = 0.0;
                
                for (int32_t i_68919 = 0; i_68919 < D_68253; i_68919++) {
                    double x_68369 = *(double *) &mem_69269.mem[i_68919 * 8];
                    bool cond_68370 = slt32(i_68921, i_68919);
                    double res_68371;
                    
                    if (cond_68370) {
                        res_68371 = 0.0;
                    } else {
                        bool cond_68372 = i_68921 == i_68919;
                        double res_68373;
                        
                        if (cond_68372) {
                            bool y_68375 = slt32(i_68921, D_68253);
                            bool index_certs_68377;
                            
                            if (!y_68375) {
                                ctx->error =
                                    msgprintf("Error at %s:\n%s%d%s%d%s\n",
                                              "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76 -> tools/KnossosFuthark/gmm_wrapper.fut:9:3-76 -> tools/KnossosFuthark/gmm_knossos.fut:131:57-139:174 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:133:81-139:172 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:136:147-137:169 -> tools/KnossosFuthark/gmm_knossos.fut:99:3-107:102 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:101:13-107:101 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:106:37-40",
                                              "Index [", i_68921,
                                              "] out of bounds for array of shape [",
                                              D_68253, "].");
                                if (memblock_unref(ctx, &mem_69269,
                                                   "mem_69269") != 0)
                                    return 1;
                                if (memblock_unref(ctx, &mem_69265,
                                                   "mem_69265") != 0)
                                    return 1;
                                return 1;
                            }
                            
                            double lifted_0_exp_arg_68378 =
                                   *(double *) &qs_mem_69261.mem[(i_68924 *
                                                                  D_68242 +
                                                                  i_68921) * 8];
                            double res_68379;
                            
                            res_68379 = futrts_exp64(lifted_0_exp_arg_68378);
                            res_68373 = res_68379;
                        } else {
                            int32_t y_68380 = D_68253 - 1;
                            int32_t x_68381 = D_68253 * y_68380;
                            int32_t res_68382 = sdiv32(x_68381, 2);
                            int32_t gmm_knossos_tri_arg_68383 = D_68253 -
                                    i_68919;
                            int32_t y_68384 = gmm_knossos_tri_arg_68383 - 1;
                            int32_t x_68385 = gmm_knossos_tri_arg_68383 *
                                    y_68384;
                            int32_t res_68386 = sdiv32(x_68385, 2);
                            int32_t x_68387 = res_68382 - res_68386;
                            int32_t x_68388 = i_68921 - i_68919;
                            int32_t y_68389 = x_68388 - 1;
                            int32_t i_68390 = x_68387 + y_68389;
                            bool x_68391 = sle32(0, i_68390);
                            bool y_68392 = slt32(i_68390, triD_68244);
                            bool bounds_check_68393 = x_68391 && y_68392;
                            bool index_certs_68394;
                            
                            if (!bounds_check_68393) {
                                ctx->error =
                                    msgprintf("Error at %s:\n%s%d%s%d%s\n",
                                              "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76 -> tools/KnossosFuthark/gmm_wrapper.fut:9:3-76 -> tools/KnossosFuthark/gmm_knossos.fut:131:57-139:174 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:133:81-139:172 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:136:147-137:169 -> tools/KnossosFuthark/gmm_knossos.fut:99:3-107:102 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:101:13-107:101 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:107:33-100",
                                              "Index [", i_68390,
                                              "] out of bounds for array of shape [",
                                              triD_68244, "].");
                                if (memblock_unref(ctx, &mem_69269,
                                                   "mem_69269") != 0)
                                    return 1;
                                if (memblock_unref(ctx, &mem_69265,
                                                   "mem_69265") != 0)
                                    return 1;
                                return 1;
                            }
                            
                            double res_68395 =
                                   *(double *) &icf_mem_69262.mem[(i_68924 *
                                                                   triD_68244 +
                                                                   i_68390) *
                                                                  8];
                            
                            res_68373 = res_68395;
                        }
                        res_68371 = res_68373;
                    }
                    
                    double res_68396 = x_68369 * res_68371;
                    double res_68367 = res_68396 + redout_68918;
                    double redout_tmp_69571 = res_68367;
                    
                    redout_68918 = redout_tmp_69571;
                }
                res_68364 = redout_68918;
                
                double res_68397 = res_68364 * res_68364;
                double res_68362 = res_68397 + redout_68920;
                double redout_tmp_69570 = res_68362;
                
                redout_68920 = redout_tmp_69570;
            }
            res_68359 = redout_68920;
            
            double y_68398 = 0.5 * res_68359;
            double res_68399 = x_68349 - y_68398;
            
            *(double *) &mem_69265.mem[i_68924 * 8] = res_68399;
        }
        
        double res_68400;
        double redout_68926 = 0.0;
        
        for (int32_t i_68927 = 0; i_68927 < K_68238; i_68927++) {
            double res_elem_68906 = *(double *) &mem_69265.mem[i_68927 * 8];
            double res_68410;
            
            res_68410 = futrts_exp64(res_elem_68906);
            
            double res_68403 = res_68410 + redout_68926;
            double redout_tmp_69572 = res_68403;
            
            redout_68926 = redout_tmp_69572;
        }
        res_68400 = redout_68926;
        
        double res_68411;
        
        res_68411 = futrts_log64(res_68400);
        
        double res_68330 = res_68411 + redout_68928;
        double redout_tmp_69566 = res_68330;
        
        redout_68928 = redout_tmp_69566;
    }
    res_68327 = redout_68928;
    if (memblock_unref(ctx, &mem_69265, "mem_69265") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69269, "mem_69269") != 0)
        return 1;
    
    double res_68412 = sitofp_i32_f64(N_68236);
    double res_68413;
    double redout_68930 = 0.0;
    
    for (int32_t i_68931 = 0; i_68931 < K_68238; i_68931++) {
        double alphas_elem_68907 = *(double *) &alphas_mem_69259.mem[i_68931 *
                                                                     8];
        double res_68423;
        
        res_68423 = futrts_exp64(alphas_elem_68907);
        
        double res_68416 = res_68423 + redout_68930;
        double redout_tmp_69573 = res_68416;
        
        redout_68930 = redout_tmp_69573;
    }
    res_68413 = redout_68930;
    
    double res_68424;
    
    res_68424 = futrts_log64(res_68413);
    
    double y_68425 = res_68412 * res_68424;
    double y_68426 = res_68327 - y_68425;
    double x_68427 = x_68293 + y_68426;
    int32_t y_68428 = 1 + wishart_m_68251;
    int32_t n_68429 = D_68253 + y_68428;
    double x_68430 = wishart_gamma_68250 * wishart_gamma_68250;
    double res_68431 = sitofp_i32_f64(wishart_m_68251);
    int32_t lifted_0_to_float_arg_68432 = D_68253 * n_68429;
    double res_68433 = sitofp_i32_f64(lifted_0_to_float_arg_68432);
    double res_68434;
    
    res_68434 = futrts_log64(wishart_gamma_68250);
    
    double y_68435 = res_68434 - 0.34657359027997264;
    double x_68436 = res_68433 * y_68435;
    double res_68437 = sitofp_i32_f64(n_68429);
    double log_gamma_distrib_arg_68438 = 0.5 * res_68437;
    int32_t y_68439 = D_68253 - 1;
    int32_t lifted_0_to_float_arg_68440 = D_68253 * y_68439;
    double res_68441 = sitofp_i32_f64(lifted_0_to_float_arg_68440);
    double x_68442 = 0.28618247146235004 * res_68441;
    double res_68443;
    double redout_68932 = 0.0;
    
    for (int32_t i_68933 = 0; i_68933 < D_68253; i_68933++) {
        double res_68448 = sitofp_i32_f64(i_68933);
        double y_68449 = 0.5 * res_68448;
        double lifted_0_lgamma_arg_68450 = log_gamma_distrib_arg_68438 -
               y_68449;
        double res_68451;
        
        res_68451 = futrts_lgamma64(lifted_0_lgamma_arg_68450);
        
        double res_68446 = res_68451 + redout_68932;
        double redout_tmp_69574 = res_68446;
        
        redout_68932 = redout_tmp_69574;
    }
    res_68443 = redout_68932;
    
    double res_68452 = x_68442 + res_68443;
    double y_68453 = x_68436 - res_68452;
    double res_68454;
    double redout_68940 = 0.0;
    
    for (int32_t i_68941 = 0; i_68941 < K_68238; i_68941++) {
        double res_68465;
        double redout_68934 = 0.0;
        
        for (int32_t i_68935 = 0; i_68935 < D_68253; i_68935++) {
            bool y_68471 = slt32(i_68935, D_68253);
            bool index_certs_68473;
            
            if (!y_68471) {
                ctx->error = msgprintf("Error at %s:\n%s%d%s%d%s\n",
                                       "tools/KnossosFuthark/gmm_wrapper.fut:3:1-9:76 -> tools/KnossosFuthark/gmm_wrapper.fut:9:3-76 -> tools/KnossosFuthark/gmm_knossos.fut:141:223-145:259 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:143:236-145:258 -> tools/KnossosFuthark/gmm_knossos.fut:123:57-74 -> tools/KnossosFuthark/gmm_knossos.fut:34:41-64 -> /futlib/array.fut:136:3-17 -> /futlib/soacs.fut:43:3-10 -> tools/KnossosFuthark/gmm_knossos.fut:34:60-63",
                                       "Index [", i_68935,
                                       "] out of bounds for array of shape [",
                                       D_68253, "].");
                if (memblock_unref(ctx, &mem_69269, "mem_69269") != 0)
                    return 1;
                if (memblock_unref(ctx, &mem_69265, "mem_69265") != 0)
                    return 1;
                return 1;
            }
            
            double lifted_0_exp_arg_68474 =
                   *(double *) &qs_mem_69261.mem[(i_68941 * D_68242 + i_68935) *
                                                 8];
            double res_68475;
            
            res_68475 = futrts_exp64(lifted_0_exp_arg_68474);
            
            double res_68476 = res_68475 * res_68475;
            double res_68468 = res_68476 + redout_68934;
            double redout_tmp_69576 = res_68468;
            
            redout_68934 = redout_tmp_69576;
        }
        res_68465 = redout_68934;
        
        double res_68477;
        double redout_68936 = 0.0;
        
        for (int32_t i_68937 = 0; i_68937 < triD_68244; i_68937++) {
            double x_68481 = *(double *) &icf_mem_69262.mem[(i_68941 *
                                                             triD_68244 +
                                                             i_68937) * 8];
            double res_68482 = x_68481 * x_68481;
            double res_68480 = res_68482 + redout_68936;
            double redout_tmp_69577 = res_68480;
            
            redout_68936 = redout_tmp_69577;
        }
        res_68477 = redout_68936;
        
        double y_68483 = res_68465 + res_68477;
        double y_68484 = x_68430 * y_68483;
        double x_68485 = 0.5 * y_68484;
        double res_68486;
        double redout_68938 = 0.0;
        
        for (int32_t i_68939 = 0; i_68939 < D_68253; i_68939++) {
            double x_68490 = *(double *) &qs_mem_69261.mem[(i_68941 * D_68242 +
                                                            i_68939) * 8];
            double res_68489 = x_68490 + redout_68938;
            double redout_tmp_69578 = res_68489;
            
            redout_68938 = redout_tmp_69578;
        }
        res_68486 = redout_68938;
        
        double y_68491 = res_68431 * res_68486;
        double x_68492 = x_68485 - y_68491;
        double res_68493 = x_68492 - y_68453;
        double res_68457 = res_68493 + redout_68940;
        double redout_tmp_69575 = res_68457;
        
        redout_68940 = redout_tmp_69575;
    }
    res_68454 = redout_68940;
    
    double res_68494 = x_68427 + res_68454;
    
    scalar_out_69565 = res_68494;
    *out_scalar_out_69652 = scalar_out_69565;
    if (memblock_unref(ctx, &mem_69269, "mem_69269") != 0)
        return 1;
    if (memblock_unref(ctx, &mem_69265, "mem_69265") != 0)
        return 1;
    return 0;
}
struct futhark_f64_1d {
    struct memblock mem;
    int64_t shape[1];
} ;
struct futhark_f64_1d *futhark_new_f64_1d(struct futhark_context *ctx,
                                          double *data, int64_t dim0)
{
    struct futhark_f64_1d *bad = NULL;
    struct futhark_f64_1d *arr =
                          (struct futhark_f64_1d *) malloc(sizeof(struct futhark_f64_1d));
    
    if (arr == NULL)
        return bad;
    lock_lock(&ctx->lock);
    arr->mem.references = NULL;
    if (memblock_alloc(ctx, &arr->mem, dim0 * sizeof(double), "arr->mem"))
        return NULL;
    arr->shape[0] = dim0;
    memmove(arr->mem.mem + 0, data + 0, dim0 * sizeof(double));
    lock_unlock(&ctx->lock);
    return arr;
}
struct futhark_f64_1d *futhark_new_raw_f64_1d(struct futhark_context *ctx,
                                              char *data, int offset,
                                              int64_t dim0)
{
    struct futhark_f64_1d *bad = NULL;
    struct futhark_f64_1d *arr =
                          (struct futhark_f64_1d *) malloc(sizeof(struct futhark_f64_1d));
    
    if (arr == NULL)
        return bad;
    lock_lock(&ctx->lock);
    arr->mem.references = NULL;
    if (memblock_alloc(ctx, &arr->mem, dim0 * sizeof(double), "arr->mem"))
        return NULL;
    arr->shape[0] = dim0;
    memmove(arr->mem.mem + 0, data + offset, dim0 * sizeof(double));
    lock_unlock(&ctx->lock);
    return arr;
}
int futhark_free_f64_1d(struct futhark_context *ctx, struct futhark_f64_1d *arr)
{
    lock_lock(&ctx->lock);
    if (memblock_unref(ctx, &arr->mem, "arr->mem") != 0)
        return 1;
    lock_unlock(&ctx->lock);
    free(arr);
    return 0;
}
int futhark_values_f64_1d(struct futhark_context *ctx,
                          struct futhark_f64_1d *arr, double *data)
{
    lock_lock(&ctx->lock);
    memmove(data + 0, arr->mem.mem + 0, arr->shape[0] * sizeof(double));
    lock_unlock(&ctx->lock);
    return 0;
}
char *futhark_values_raw_f64_1d(struct futhark_context *ctx,
                                struct futhark_f64_1d *arr)
{
    return arr->mem.mem;
}
int64_t *futhark_shape_f64_1d(struct futhark_context *ctx,
                              struct futhark_f64_1d *arr)
{
    return arr->shape;
}
struct futhark_f64_2d {
    struct memblock mem;
    int64_t shape[2];
} ;
struct futhark_f64_2d *futhark_new_f64_2d(struct futhark_context *ctx,
                                          double *data, int64_t dim0,
                                          int64_t dim1)
{
    struct futhark_f64_2d *bad = NULL;
    struct futhark_f64_2d *arr =
                          (struct futhark_f64_2d *) malloc(sizeof(struct futhark_f64_2d));
    
    if (arr == NULL)
        return bad;
    lock_lock(&ctx->lock);
    arr->mem.references = NULL;
    if (memblock_alloc(ctx, &arr->mem, dim0 * dim1 * sizeof(double),
                       "arr->mem"))
        return NULL;
    arr->shape[0] = dim0;
    arr->shape[1] = dim1;
    memmove(arr->mem.mem + 0, data + 0, dim0 * dim1 * sizeof(double));
    lock_unlock(&ctx->lock);
    return arr;
}
struct futhark_f64_2d *futhark_new_raw_f64_2d(struct futhark_context *ctx,
                                              char *data, int offset,
                                              int64_t dim0, int64_t dim1)
{
    struct futhark_f64_2d *bad = NULL;
    struct futhark_f64_2d *arr =
                          (struct futhark_f64_2d *) malloc(sizeof(struct futhark_f64_2d));
    
    if (arr == NULL)
        return bad;
    lock_lock(&ctx->lock);
    arr->mem.references = NULL;
    if (memblock_alloc(ctx, &arr->mem, dim0 * dim1 * sizeof(double),
                       "arr->mem"))
        return NULL;
    arr->shape[0] = dim0;
    arr->shape[1] = dim1;
    memmove(arr->mem.mem + 0, data + offset, dim0 * dim1 * sizeof(double));
    lock_unlock(&ctx->lock);
    return arr;
}
int futhark_free_f64_2d(struct futhark_context *ctx, struct futhark_f64_2d *arr)
{
    lock_lock(&ctx->lock);
    if (memblock_unref(ctx, &arr->mem, "arr->mem") != 0)
        return 1;
    lock_unlock(&ctx->lock);
    free(arr);
    return 0;
}
int futhark_values_f64_2d(struct futhark_context *ctx,
                          struct futhark_f64_2d *arr, double *data)
{
    lock_lock(&ctx->lock);
    memmove(data + 0, arr->mem.mem + 0, arr->shape[0] * arr->shape[1] *
            sizeof(double));
    lock_unlock(&ctx->lock);
    return 0;
}
char *futhark_values_raw_f64_2d(struct futhark_context *ctx,
                                struct futhark_f64_2d *arr)
{
    return arr->mem.mem;
}
int64_t *futhark_shape_f64_2d(struct futhark_context *ctx,
                              struct futhark_f64_2d *arr)
{
    return arr->shape;
}
int futhark_entry_rev_gmm_objective(struct futhark_context *ctx,
                                    struct futhark_f64_1d **out0,
                                    struct futhark_f64_2d **out1,
                                    struct futhark_f64_2d **out2,
                                    struct futhark_f64_2d **out3, const
                                    struct futhark_f64_2d *in0, const
                                    struct futhark_f64_1d *in1, const
                                    struct futhark_f64_2d *in2, const
                                    struct futhark_f64_2d *in3, const
                                    struct futhark_f64_2d *in4, const
                                    double in5, const int32_t in6, const
                                    double in7)
{
    struct memblock x_mem_69258;
    
    x_mem_69258.references = NULL;
    
    struct memblock alphas_mem_69259;
    
    alphas_mem_69259.references = NULL;
    
    struct memblock means_mem_69260;
    
    means_mem_69260.references = NULL;
    
    struct memblock qs_mem_69261;
    
    qs_mem_69261.references = NULL;
    
    struct memblock icf_mem_69262;
    
    icf_mem_69262.references = NULL;
    
    int32_t N_68495;
    int32_t D_68496;
    int32_t K_68497;
    int32_t K_68498;
    int32_t D_68499;
    int32_t K_68500;
    int32_t D_68501;
    int32_t K_68502;
    int32_t triD_68503;
    double wishart_gamma_68509;
    int32_t wishart_m_68510;
    double d_r_68511;
    struct memblock out_mem_69579;
    
    out_mem_69579.references = NULL;
    
    int32_t out_arrsizze_69580;
    struct memblock out_mem_69581;
    
    out_mem_69581.references = NULL;
    
    int32_t out_arrsizze_69582;
    int32_t out_arrsizze_69583;
    struct memblock out_mem_69584;
    
    out_mem_69584.references = NULL;
    
    int32_t out_arrsizze_69585;
    int32_t out_arrsizze_69586;
    struct memblock out_mem_69587;
    
    out_mem_69587.references = NULL;
    
    int32_t out_arrsizze_69588;
    int32_t out_arrsizze_69589;
    
    lock_lock(&ctx->lock);
    x_mem_69258 = in0->mem;
    N_68495 = in0->shape[0];
    D_68496 = in0->shape[1];
    alphas_mem_69259 = in1->mem;
    K_68497 = in1->shape[0];
    means_mem_69260 = in2->mem;
    K_68498 = in2->shape[0];
    D_68499 = in2->shape[1];
    qs_mem_69261 = in3->mem;
    K_68500 = in3->shape[0];
    D_68501 = in3->shape[1];
    icf_mem_69262 = in4->mem;
    K_68502 = in4->shape[0];
    triD_68503 = in4->shape[1];
    wishart_gamma_68509 = in5;
    wishart_m_68510 = in6;
    d_r_68511 = in7;
    
    int ret = futrts_rev_gmm_objective(ctx, &out_mem_69579, &out_arrsizze_69580,
                                       &out_mem_69581, &out_arrsizze_69582,
                                       &out_arrsizze_69583, &out_mem_69584,
                                       &out_arrsizze_69585, &out_arrsizze_69586,
                                       &out_mem_69587, &out_arrsizze_69588,
                                       &out_arrsizze_69589, x_mem_69258,
                                       alphas_mem_69259, means_mem_69260,
                                       qs_mem_69261, icf_mem_69262, N_68495,
                                       D_68496, K_68497, K_68498, D_68499,
                                       K_68500, D_68501, K_68502, triD_68503,
                                       wishart_gamma_68509, wishart_m_68510,
                                       d_r_68511);
    
    if (ret == 0) {
        assert((*out0 =
                (struct futhark_f64_1d *) malloc(sizeof(struct futhark_f64_1d))) !=
            NULL);
        (*out0)->mem = out_mem_69579;
        (*out0)->shape[0] = out_arrsizze_69580;
        assert((*out1 =
                (struct futhark_f64_2d *) malloc(sizeof(struct futhark_f64_2d))) !=
            NULL);
        (*out1)->mem = out_mem_69581;
        (*out1)->shape[0] = out_arrsizze_69582;
        (*out1)->shape[1] = out_arrsizze_69583;
        assert((*out2 =
                (struct futhark_f64_2d *) malloc(sizeof(struct futhark_f64_2d))) !=
            NULL);
        (*out2)->mem = out_mem_69584;
        (*out2)->shape[0] = out_arrsizze_69585;
        (*out2)->shape[1] = out_arrsizze_69586;
        assert((*out3 =
                (struct futhark_f64_2d *) malloc(sizeof(struct futhark_f64_2d))) !=
            NULL);
        (*out3)->mem = out_mem_69587;
        (*out3)->shape[0] = out_arrsizze_69588;
        (*out3)->shape[1] = out_arrsizze_69589;
    }
    lock_unlock(&ctx->lock);
    return ret;
}
int futhark_entry_gmm_objective(struct futhark_context *ctx, double *out0, const
                                struct futhark_f64_2d *in0, const
                                struct futhark_f64_1d *in1, const
                                struct futhark_f64_2d *in2, const
                                struct futhark_f64_2d *in3, const
                                struct futhark_f64_2d *in4, const double in5,
                                const int32_t in6)
{
    struct memblock x_mem_69258;
    
    x_mem_69258.references = NULL;
    
    struct memblock alphas_mem_69259;
    
    alphas_mem_69259.references = NULL;
    
    struct memblock means_mem_69260;
    
    means_mem_69260.references = NULL;
    
    struct memblock qs_mem_69261;
    
    qs_mem_69261.references = NULL;
    
    struct memblock icf_mem_69262;
    
    icf_mem_69262.references = NULL;
    
    int32_t N_68236;
    int32_t D_68237;
    int32_t K_68238;
    int32_t K_68239;
    int32_t D_68240;
    int32_t K_68241;
    int32_t D_68242;
    int32_t K_68243;
    int32_t triD_68244;
    double wishart_gamma_68250;
    int32_t wishart_m_68251;
    double scalar_out_69565;
    
    lock_lock(&ctx->lock);
    x_mem_69258 = in0->mem;
    N_68236 = in0->shape[0];
    D_68237 = in0->shape[1];
    alphas_mem_69259 = in1->mem;
    K_68238 = in1->shape[0];
    means_mem_69260 = in2->mem;
    K_68239 = in2->shape[0];
    D_68240 = in2->shape[1];
    qs_mem_69261 = in3->mem;
    K_68241 = in3->shape[0];
    D_68242 = in3->shape[1];
    icf_mem_69262 = in4->mem;
    K_68243 = in4->shape[0];
    triD_68244 = in4->shape[1];
    wishart_gamma_68250 = in5;
    wishart_m_68251 = in6;
    
    int ret = futrts_gmm_objective(ctx, &scalar_out_69565, x_mem_69258,
                                   alphas_mem_69259, means_mem_69260,
                                   qs_mem_69261, icf_mem_69262, N_68236,
                                   D_68237, K_68238, K_68239, D_68240, K_68241,
                                   D_68242, K_68243, triD_68244,
                                   wishart_gamma_68250, wishart_m_68251);
    
    if (ret == 0) {
        *out0 = scalar_out_69565;
    }
    lock_unlock(&ctx->lock);
    return ret;
}
