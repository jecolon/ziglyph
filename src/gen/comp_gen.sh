#!/bin/sh
# comp_gen.sh - Generates the src/componets.zig file for the Ziglyph library. Since many Ziglyph
# componets are auto-generated, the library public exports have to be auto-generated as well. That's
# what this script does. Normaylly, library users need not run this.

for FULL_PATH in `find ../components/autogen -type f | sort`; do
    STRUCT_NAME=`basename -s .zig $FULL_PATH`;
    REAL_PATH=`echo $FULL_PATH | cut -b 1-3 --complement`;
    echo "$STRUCT_NAME $REAL_PATH"
done | awk -e '
{
    names[$1] = $2;
}

END {
    for (name in names) {
        printf("pub const %s = @import(\"%s\");\n", name, names[name]); 
    }
}
' | sort -k3 | cat tpl/components_tpl.txt - > ../components.zig
