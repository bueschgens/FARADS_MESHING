module FARADS_MESHING

    using FARADS_GEOM

    using WriteVTK
    using MAT
    
    include("./discret_types.jl")

    include("./mesh_types.jl")

    include("./discret_fct.jl")
    
    include("./mesh_compose.jl")

    include("./ext_tgrid_fct.jl")
    include("./ext_import_fct.jl")

    include("./mat_fct.jl")

    include("./ext_export_fct.jl")

    export Disc3D, Face, Part

    export Mesh3D, VecMesh3D

    export discretisation
    
    export reverse_nvec_of_faces!, delete_face_of_part!
    export join_parts, join_faces_of_part

    export compose_mesh, make_mesh_vector, information_mesh
    export get_part_of_face

    export import_tgrid

    export get_nvec, get_com_and_area

    export convert_mesh_mat2struct

    export export_vtk

    export debug_part_node_numbering
    export debug_model_node_numbering
    export debug_model_nvec_direction
    export debug_single_element_of_model_node_numbering

    export reverse_node_numbers_of_elements!

    export get_mean_elem_size_of_face
    export get_mean_elem_size_of_part
    export mynorm


end