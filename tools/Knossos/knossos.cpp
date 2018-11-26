#include "knossos.h"

namespace ks {
  // 1m seemed to work fine when I ran the benchmark on my local
  // machine but to succeed on Azure DevOps it seems to need 10b.  I
  // have no idea what the reason for that difference is.
  allocator g_alloc(10 * 1000 * 1000 * 1000);
}
