#========================================================================
# This is a sample configuration file for the diskcache
#------------------------------------------------------------------------
# SERVER_PORT:
#------------------------------------------------------------------------
SERVER_PORT=20222
#------------------------------------------------------------------------
# CONCURRENCY:
#   Number of mount points to scan concurrently.
#------------------------------------------------------------------------
CONCURRENCY=10
#------------------------------------------------------------------------
# LOG:
#   Specify where the log messages should be written.
#------------------------------------------------------------------------
LOG=diskcache
#------------------------------------------------------------------------
# LOG_DIRECTORY:
#   Specify the directory to capture logging information.
#------------------------------------------------------------------------
LOG_DIRECTORY=/var/log/diskcache
#------------------------------------------------------------------------
# LOG_ROTATE_ENTRY_COUNT:
#   Specify number of lines before rotating logs
#------------------------------------------------------------------------
LOG_ROTATE_ENTRY_COUNT=10000
#------------------------------------------------------------------------
# OUTPUT_ASCII:
#   Filename for the ascii output; Use '-' to direct to standard out.
#------------------------------------------------------------------------
OUTPUT_ASCII=/var/lib/diskcache/ascii_cache.dat
#------------------------------------------------------------------------
# OUTPUT_ASCII_VERSION:
#   Version of the ascii cache dump format to use.
#   By default, the latest version is used.
#------------------------------------------------------------------------
OUTPUT_ASCII_VERSION=0x00FF
#------------------------------------------------------------------------
# OUTPUT_BINARY:
#   Filename for the binary output; Use '-' to direct to standard out.
#------------------------------------------------------------------------
OUTPUT_BINARY=/var/lib/diskcache/binary_cache.dat
#------------------------------------------------------------------------
# OUTPUT_BINARY_VERSION:
#   Version of the binary cache dump format to use.
#   By default, the latest version is used.
#------------------------------------------------------------------------
OUTPUT_BINARY_VERSION=0x0101
#------------------------------------------------------------------------
# RWLOCK_INTERVAL_MS
#   Length of time in milliseconds to wait before retrying to acquire
#   mutex lock
#------------------------------------------------------------------------
RWLOCK_INTERVAL_MS=2000
#------------------------------------------------------------------------
# RWLOCK_TIMEOUT_MS
#   Length of time in milliseconds to try and acquire mutex lock
#------------------------------------------------------------------------
RWLOCK_TIMEOUT_MS=0

#------------------------------------------------------------------------
# SCAN_INTERVAL
#   Number of milliseconds to pause between scans.
#   Default: 16 seconds
#------------------------------------------------------------------------
SCAN_INTERVAL=4096000
#------------------------------------------------------------------------
# STAT_TIMEOUT
#   Number of seconds to wait for system stat call to return.
#   Default: 5 seconds
#------------------------------------------------------------------------
STAT_TIMEOUT=300
#------------------------------------------------------------------------
# EXTENSIONS:
#   Each line represents a trailing pattern of files to be added to
#   the cache.
#------------------------------------------------------------------------
[EXTENSIONS]
.gwf

#------------------------------------------------------------------------
# EXCLUDED_DIRECTORIES:
#   Each line represents a directory pattern not to be searched.
#------------------------------------------------------------------------
[EXCLUDED_DIRECTORIES]
lost+found

#------------------------------------------------------------------------
# MOUNT_POINTS:
#   Each line represents a top level directory to be searched for files
#   to populate the cache.
#------------------------------------------------------------------------
[MOUNT_POINTS]
/cvmfs/gwosc.osgstorage.org/gwdata/O1/strain.16k/frame.v1/H1
/cvmfs/gwosc.osgstorage.org/gwdata/O1/strain.16k/frame.v1/L1
/cvmfs/gwosc.osgstorage.org/gwdata/O2/strain.16k/frame.v1/H1
/cvmfs/gwosc.osgstorage.org/gwdata/O2/strain.16k/frame.v1/L1
/cvmfs/gwosc.osgstorage.org/gwdata/O2/strain.16k/frame.v1/V1
