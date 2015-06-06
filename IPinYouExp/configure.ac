#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([FULL-PACKAGE-NAME], [VERSION], [BUG-REPORT-ADDRESS])
# AC_CONFIG_HEADERS([config.h])

# Checks for programs.
# AC_PROG_CXX
# AC_PROG_CC
# m4_include([m4/m4-ax_cxx_compile_stdcxx_11.m4])
# AC_PROG_CXX
# AC_LANG_PUSH([C++])
# AX_CXX_COMPILE_STDCXX_11
# AC_LANG_POP([C++])


# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.
AC_CHECK_HEADER_STDBOOL

# Checks for library functions.

# Generate RcppAttribute
Rscript -e "Rcpp::compileAttributes()"

# Generate roxygen
Rscript -e "roxygen2::roxygenise('.', roclets = 'namespace')"