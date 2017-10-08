!+ This file will try to wrap the portions needed to use colrad 
module fidanet

USE libfida

implicit none

type(LocalProfiles)       :: Plasma

real(8)                   :: ai = H_2_amu
real(8)                   :: ab = H_2_amu
integer                   :: impq = 6
real(8)                   :: eqt = 10 * (4.41d7**(-1))

real(8), dimension(6)     :: states
real(8), dimension(6)     :: dens
real(8)                   :: photons

contains

subroutine settables
    colrad_threshold = 0.0
    call read_tables()
end subroutine settables

subroutine getdens(dene,impq,Zeff,denp,denimp)
    real(8), intent(in)                    :: dene
    integer, intent(in)                    :: impq
    real(8), intent(in)                    :: Zeff
    real(8), intent(out)                   :: denp
    real(8), intent(out)                   :: denimp

    denimp = ((Zeff-1.d0)/(impq*(impq-1.d0)))*dene
    denp = dene - impq*denimp
end subroutine getdens

subroutine setplasma(dene, denp, denimp, te, ti)
    real(8), intent(in)                    :: dene
    real(8), intent(in)                    :: denp
    real(8), intent(in)                    :: denimp
    real(8), intent(in)                    :: te
    real(8), intent(in)                    :: ti
    
    Plasma%dene = dene
    Plasma%denimp = denimp
    Plasma%denp = denp
    Plasma%te = te
    Plasma%ti = ti
    Plasma%in_plasma = .True.
end subroutine setplasma

subroutine setinputs(ai, ab, impq)
    real(8), intent(in)                    :: ai
    real(8), intent(in)                    :: ab
    integer, intent(in)                    :: impq

    inputs%ai = ai
    inputs%ab = ab
    inputs%impurity_charge = impq
    inputs%tables_file = '/home/kenny/Documents/FidaSim/FIDASIM-master/src/atomic_tables.h5'
    inputs%calc_npa = 0
    inputs%verbose = 1
end subroutine setinputs

subroutine calcvn(i_type, eb, vn)
    integer, intent(in)                    :: i_type
    real(8), intent(in)                    :: eb
    real(8), dimension(3), intent(out)     :: vn

    real(8)                                :: b_amu

    if(i_type.eq.beam_ion) then
        b_amu = inputs%ab
    else
        b_amu = inputs%ai
    endif

    vn(1) = sqrt(eb / (v2_to_E_per_amu * b_amu))
    vn(2) = 0.0
    vn(3) = 0.0
end subroutine calcvn

subroutine setstates(newstates, states)
    real(8), dimension(6), intent(in)      :: newstates
    real(8), dimension(6), intent(inout)   :: states

    states = newstates
end subroutine setstates

subroutine testcol(i_type,eb,dt,states,dens,photons)
    integer, intent(in)                    :: i_type
        !+ Ion/Neutral type (beam,thermal)
    real(8), intent(in)                    :: eb
        !+ Neutral velocitiy [cm/s]
    real(8), intent(in)                    :: dt
        !+ Time interval [s]
    real(8), dimension(6), intent(inout)   :: states
        !+ Density of states
    real(8), dimension(6), intent(out)     :: dens
        !+ Density of neutrals
    real(8), intent(out)                   :: photons
        !+ Emitted photons(3->2)

    real(8), dimension(3)                  :: vn

    call calcvn(i_type, eb, vn)

    call colrad(Plasma,i_type,vn,dt,states,dens,photons)
end subroutine testcol


end module fidanet



! eb [1eV,100keV]
!Te / Ti [1eV,20keV]
!ne [0,2e14]
!Zeff [1,6]    <-- make thing to determine denp,denimp from Zeff and dene

! Start w/ ground state, dt big ~ Einstein inverted * 10
! Einstein inverted not always big enough for some choices of parameters that are inside the
!   (admittedly massive) ranges given.
! In these instances, 1 should still work


!+important plasma parameters:
!+ denp
!+ dene
!+ denimp
!+ ti
!+ te
!+ in_plasma (needs to be true
!+ vrot
!+
!+important inputs parameters:
!+ calc_npa
!+ ab
!+ ai
!+ verbose
!+ 