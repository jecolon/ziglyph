#!/bin/sh

for FULL_PATH in `find components/autogen -type f | sort`; do
    STRUCT_NAME=`basename -s .zig $FULL_PATH`;
    echo "$STRUCT_NAME $FULL_PATH"
done | awk -e '
{
    names[$1] = $2;
}

END {
    for (name in names) {
        printf("pub const %s = @import(\"%s\");\n", name, names[name]); 
    }
}
' | sort -k3 | cat components_tpl.txt - > components.zig
