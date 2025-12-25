#!/usr/bin/awk -f
# Idempotent header patch for C89:
# - Replace union-based JSPropDef with struct-of-fields
# - Replace macros using designated initializers with positional ones
#
# Usage:
#   awk -f patching/patch_build_header.awk mquickjs_build.h > mquickjs_build.h.new && mv mquickjs_build.h.new mquickjs_build.h

BEGIN {
  in_jspropdef = 0
  replaced_jspropdef = 0
}

function print_new_jspropdef_block() {
  print "typedef struct JSPropFunc {"
  print "    uint8_t length;"
  print "    const char *magic;"
  print "    const char *cproto_name;"
  print "    const char *func_name;"
  print "} JSPropFunc;"
  print ""
  print "typedef struct JSPropGetSet {"
  print "    const char *magic;"
  print "    const char *cproto_name;"
  print "    const char *get_func_name;"
  print "    const char *set_func_name;"
  print "} JSPropGetSet;"
  print ""
  print "typedef struct JSPropDef {"
  print "    int def_type;"
  print "    const char *name;"
  print "    JSPropFunc func;        /* used when def_type == JS_DEF_CFUNC */"
  print "    JSPropGetSet getset;    /* used when def_type == JS_DEF_CGETSET */"
  print "    double f64;             /* used when def_type == JS_DEF_PROP_DOUBLE */"
  print "    const JSClassDef *class1; /* used when def_type == JS_DEF_CLASS */"
  print "    const char *str;        /* used when def_type == JS_DEF_PROP_STRING */"
  print "} JSPropDef;"
}

function print_new_macro(name, body,   line) {
  line = "#define " name " " body
  print line
}

# Detect start of old union-based JSPropDef
/^[[:space:]]*typedef[[:space:]]+struct[[:space:]]+JSPropDef[[:space:]]*\{/ {
  if (!replaced_jspropdef) {
    in_jspropdef = 1
    replaced_jspropdef = 1
    print ""
    print_new_jspropdef_block()
    print ""
  }
  next
}

# Skip until end of old JSPropDef block
in_jspropdef && /^\}[[:space:]]*JSPropDef[[:space:]]*;/ {
  in_jspropdef = 0
  next
}
in_jspropdef { next }

# Replace macros that used designated initializers (C99) with positional (C89)
# These are idempotent: if already replaced, patterns below won't match.

# JS_PROP_END
/^[[:space:]]*#define[[:space:]]+JS_PROP_END\b/ {
  print_new_macro("JS_PROP_END", "{ JS_DEF_END, 0 }")
  next
}

# JS_CFUNC_DEF
/^[[:space:]]*#define[[:space:]]+JS_CFUNC_DEF\(/ {
  print_new_macro("JS_CFUNC_DEF(name, length, func_name)", "{ JS_DEF_CFUNC, (name), { (uint8_t)(length), \"0\", \"generic\", #func_name }, {0}, 0.0, 0, 0 }")
  next
}

# JS_CFUNC_MAGIC_DEF
/^[[:space:]]*#define[[:space:]]+JS_CFUNC_MAGIC_DEF\(/ {
  print_new_macro("JS_CFUNC_MAGIC_DEF(name, length, func_name, magic)", "{ JS_DEF_CFUNC, (name), { (uint8_t)(length), #magic, \"generic_magic\", #func_name }, {0}, 0.0, 0, 0 }")
  next
}

# JS_CFUNC_SPECIAL_DEF
/^[[:space:]]*#define[[:space:]]+JS_CFUNC_SPECIAL_DEF\(/ {
  print_new_macro("JS_CFUNC_SPECIAL_DEF(name, length, proto, func_name)", "{ JS_DEF_CFUNC, (name), { (uint8_t)(length), \"0\", #proto, #func_name }, {0}, 0.0, 0, 0 }")
  next
}

# JS_CGETSET_DEF
/^[[:space:]]*#define[[:space:]]+JS_CGETSET_DEF\(/ {
  print_new_macro("JS_CGETSET_DEF(name, get_name, set_name)", "{ JS_DEF_CGETSET, (name), {0}, { \"0\", \"generic\", #get_name, #set_name }, 0.0, 0, 0 }")
  next
}

# JS_CGETSET_MAGIC_DEF
/^[[:space:]]*#define[[:space:]]+JS_CGETSET_MAGIC_DEF\(/ {
  print_new_macro("JS_CGETSET_MAGIC_DEF(name, get_name, set_name, magic)", "{ JS_DEF_CGETSET, (name), {0}, { #magic, \"generic_magic\", #get_name, #set_name }, 0.0, 0, 0 }")
  next
}

# JS_PROP_CLASS_DEF
/^[[:space:]]*#define[[:space:]]+JS_PROP_CLASS_DEF\(/ {
  print_new_macro("JS_PROP_CLASS_DEF(name, cl)", "{ JS_DEF_CLASS, (name), {0}, {0}, 0.0, (cl), 0 }")
  next
}

# JS_PROP_DOUBLE_DEF
/^[[:space:]]*#define[[:space:]]+JS_PROP_DOUBLE_DEF\(/ {
  print_new_macro("JS_PROP_DOUBLE_DEF(name, val, flags)", "{ JS_DEF_PROP_DOUBLE, (name), {0}, {0}, (val), 0, 0 }")
  next
}

# JS_PROP_UNDEFINED_DEF
/^[[:space:]]*#define[[:space:]]+JS_PROP_UNDEFINED_DEF\(/ {
  print_new_macro("JS_PROP_UNDEFINED_DEF(name, flags)", "{ JS_DEF_PROP_UNDEFINED, (name) }")
  next
}

# JS_PROP_NULL_DEF
/^[[:space:]]*#define[[:space:]]+JS_PROP_NULL_DEF\(/ {
  print_new_macro("JS_PROP_NULL_DEF(name, flags)", "{ JS_DEF_PROP_NULL, (name) }")
  next
}

# JS_PROP_STRING_DEF
/^[[:space:]]*#define[[:space:]]+JS_PROP_STRING_DEF\(/ {
  print_new_macro("JS_PROP_STRING_DEF(name, cstr, flags)", "{ JS_DEF_PROP_STRING, (name), {0}, {0}, 0.0, 0, (cstr) }")
  next
}

# Default: passthrough
{ print }