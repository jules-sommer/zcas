# zCAS

***zCAS*** is a small Zig library that provides a data structure for representing [CAS Registry](https://www.cas.org/cas-data/cas-registry) identifiers. A CAS number is a unique identification number (UID) assigned in sequential, increasing order to a given chemical compound as they are identified.

A CAS number follows the format of three unsigned integers separated by hyphens, e.g. `XXXXXXX-XX-X` where `X` is any numeric digit 1 through 9. The first of the three segments can contain between two and seven digits, and is thus represented in a u24.

The first and second integers represent the actual UID assigned to a given molecular structure, and the third integer is a check digit used for error correction and allows us to check the validity of a CAS number without a database lookup.


