module FARADS_MESHING

    using FARADS_GEOM
    
    include("./discret_types.jl")
    include("./discret_fct.jl")
    include("./mesh_types.jl")
    include("./mesh_compose.jl")

    include("./ext_tgrid_fct.jl")
    include("./ext_import_fct.jl")

    export Disc3D, Face, Part

    export Mesh3D, VecMesh3D

    export discretisation
    
    export reverse_nvec_of_faces!, delete_face_of_part!
    export join_parts, join_faces_of_part

    export compose_mesh, make_mesh_vector, information_mesh
    export get_part_of_face

    export import_tgrid


end