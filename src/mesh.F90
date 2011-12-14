module mesh

  use constants
  use mesh_header
  use particle_header, only: Particle

  implicit none

contains

!===============================================================================
! GET_MESH_BIN determines the tally bin for a particle in a structured mesh
!===============================================================================

  subroutine get_mesh_bin(m, xyz, bin)

    type(StructuredMesh), pointer :: m
    real(8), intent(in)           :: xyz(:)
    integer, intent(out)          :: bin

    integer :: n
    integer :: ijk(3)
    logical :: in_mesh

    ! Get number of dimensions
    n = m % n_dimension

    ! Check for cases where particle is outside of mesh
    if (xyz(1) < m % origin(1)) then
       bin = NO_BIN_FOUND
       return
    elseif (xyz(1) > m % upper_right(1)) then
       bin = NO_BIN_FOUND
       return
    elseif (xyz(2) < m % origin(2)) then
       bin = NO_BIN_FOUND
       return
    elseif (xyz(2) > m % upper_right(2)) then
       bin = NO_BIN_FOUND
       return
    end if
    if (n > 2) then
       if (xyz(3) < m % origin(3)) then
          bin = NO_BIN_FOUND
          return
       elseif (xyz(3) > m % upper_right(3)) then
          bin = NO_BIN_FOUND
          return
       end if
    end if

    ! Determine indices
    call get_mesh_indices(m, xyz(1:n), ijk(1:n), in_mesh)

    ! Convert indices to bin
    if (in_mesh) then
       bin = mesh_indices_to_bin(m, ijk)
    else
       bin = NO_BIN_FOUND
    end if

  end subroutine get_mesh_bin

!===============================================================================
! GET_MESH_INDICES determines the indices of a particle in a structured mesh
!===============================================================================

  subroutine get_mesh_indices(m, xyz, ijk, in_mesh)

    type(StructuredMesh), pointer :: m
    real(8), intent(in)           :: xyz(:)
    integer, intent(out)          :: ijk(:)
    logical, intent(out)          :: in_mesh

    ! Find particle in mesh
    ijk = ceiling((xyz - m % origin)/m % width)

    ! Determine if particle is in mesh
    if (any(ijk < 1) .or. any(ijk > m % dimension)) then
       in_mesh = .false.
    else
       in_mesh = .true.
    end if

  end subroutine get_mesh_indices

!===============================================================================
! MESH_INDICES_TO_BIN maps (i,j) or (i,j,k) indices to a single bin number for
! use in a TallyObject scores array
!===============================================================================

  function mesh_indices_to_bin(m, ijk) result(bin)

    type(StructuredMesh), pointer :: m
    integer, intent(in)           :: ijk(:)
    integer                       :: bin

    integer :: n_x
    integer :: n_y
    integer :: n_z

    n_x = m % dimension(1)
    n_y = m % dimension(2)

    if (m % n_dimension == 2) then
       bin = (ijk(1) - 1)*n_y + ijk(2)
    elseif (m % n_dimension == 3) then
       n_z = m % dimension(3)
       bin = (ijk(1) - 1)*n_y*n_z + (ijk(2) - 1)*n_z + ijk(3)
    end if

  end function mesh_indices_to_bin

!===============================================================================
! BIN_TO_MESH_INDICES maps a single mesh bin from a TallyObject scores array to
! (i,j) or (i,j,k) indices
!===============================================================================

  subroutine bin_to_mesh_indices(m, bin, ijk)

    type(StructuredMesh), pointer :: m
    integer, intent(in)           :: bin
    integer, intent(out)          :: ijk(:)

    integer :: n_y
    integer :: n_z

    if (m % n_dimension == 2) then
       n_y = m % dimension(2)

       ijk(1) = (bin - 1)/n_y + 1
       ijk(2) = mod(bin - 1, n_y) + 1
    else if (m % n_dimension == 3) then
       n_y = m % dimension(2)
       n_z = m % dimension(3)

       ijk(1) = (bin - 1)/(n_y*n_z) + 1
       ijk(2) = mod(bin - 1, n_y*n_z)/n_z + 1
       ijk(3) = mod(bin - 1, n_z) + 1
    end if

  end subroutine bin_to_mesh_indices

end module mesh