abstract type AbstractDisc end

abstract type Disc3D <: AbstractDisc end

struct Face{T1<:AbstractFloat, T2<:Integer} <: Disc3D
    elements::Array{T2,2}
    com::Array{T1,2}
    nvec::Array{T1,2}
    area::Vector{T1}
end

struct Part{T1<:AbstractFloat,T2<:Integer} <: Disc3D
    nodes::Array{T1,2}
    faces::Array{Face{T1,T2},1}
end

