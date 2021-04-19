abstract type AbstractMesh end

struct Mesh3D{T1<:AbstractFloat, T2<:Integer} <: AbstractMesh
    nodes::Array{T1,2}
    nodes2parts::Array{T2,2}
    elements::Array{T2,2}
    com::Array{T1,2} #elementwise
    nvec::Array{T1,2} #elementwise
    area::Array{T1,1} #elementwise
    elements2parts::Array{T2,2}
    elements2faces::Array{T2,2}
    faces2parts::Array{T2,2}
    elementstatus::Array{T2,2} #only used for Part number of Element
    # first col: element number; second col: ??; third col: part number
end

struct VecMesh3D{T1<:AbstractFloat, T2<:Integer} <: AbstractMesh
    nodes::Vector{T1}
    nodes2parts::Vector{T2}
    elements::Vector{T2}
    com::Vector{T1}
    nvec::Vector{T1}
    area::Vector{T1}
    elements2parts::Vector{T2}
    elements2faces::Vector{T2}
    faces2parts::Vector{T2}
    elementstatus::Vector{T2}
    nelements::T2
    nnodes::T2
    nparts::T2
end


