# FARADS_MESHING

## FARADS - Fast and Accurate calculation of RADiation heat transfer between arbitrary three-dimensional Surfaces

FARADS provides a framework for calculating view factors of arbitrary three-dimensional geometries. With these view factors the additional application of the net radiation method for calculating exchanged heat fluxes can be used.

other modules of FARADS:
- FARADS_GEOM
- FARADS_PLOT
- FARADS_VFCALC
- FARADS_QRAD

This module provides functions and types for:
- discretization of geometrical objects of FARADS_GEOM
- composing all parts to mesh with necessary information
- utility functions for working with mesh
- read abaqus .inp files and import mesh
- read .msh files and import mesh
- read gmsh files and import mesh (work in progress)
- export to vtk file

This is used as input for the other modules of FARADS.

Special thanks to Christian Schubert for providing parts of reading gmsh and .msh files.