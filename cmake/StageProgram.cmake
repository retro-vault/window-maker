# Helper run via `cmake -P`: copy an executable script into the staged tree,
# preserving the executable bit.  `cmake -E copy` cannot set permissions.
#
# Expects -DSRC=<file> -DDSTDIR=<directory>

file(INSTALL "${SRC}"
     DESTINATION "${DSTDIR}"
     FILE_PERMISSIONS
         OWNER_READ OWNER_WRITE OWNER_EXECUTE
         GROUP_READ GROUP_EXECUTE
         WORLD_READ WORLD_EXECUTE)
