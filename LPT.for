!======================================================================!
!                 LAGRANGIAN PARTICLE TRACKING                         !
!----------------------------------------------------------------------!
!                           Bruño Fraga                                ! 
!                      Cardiff Uni 2013-2017                           !
!                        Stanford Uni 2018                             !
!                    Uni of Birmingham 2019-2024                       !
!======================================================================!
!######################################################################!      
      subroutine particle_tracking
!
!     Calculates particles' velocities and the resulting source terms
!
!######################################################################!
      use multidata
      use mpi
      use vars   
      use vars_pt
      use omp_lib, only : omp_get_num_threads,
     &                    omp_get_thread_num,
     &                    omp_set_num_threads
      implicit none

      integer i,j,k,l
      integer ib,is,ie,js,je,ks,ke  
      integer nt,m
      integer iballs_u,iballe_u,jballs_u,jballe_u,kballs_u,kballe_u
      integer iballs_v,iballe_v,jballs_v,jballe_v,kballs_v,kballe_v
      integer iballs_w,iballe_w,jballs_w,jballe_w,kballs_w,kballe_w
      real REp,rx,ry,rz
      double precision a,b,c,wx,wy,wz,Cd,ao,bo,co
      double precision dwdy,dvdz,dudz,dwdx,dvdx,dudy
      double precision dh,delta,gamma_p,ddh,ddelta
      double precision Vcell,Vp!,Vball
      double precision, allocatable, dimension(:):: ui_pt,vi_pt,wi_pt
      double precision, allocatable, dimension(:):: uoi_pt,voi_pt,woi_pt
      integer,allocatable,dimension(:)::  ip,jp,kp,ipu,jpv,kpw
      integer,dimension(nprocs) :: strider

      double precision fcol_n,fcol_t,mu_f
      double precision lambda_w,lambda_u,lambda_v
      double precision k_n,k_t,theta_col,e_col,mp
      double precision deltap

      allocate (ui_pt(np_loc),vi_pt(np_loc),wi_pt(np_loc))
      allocate (uoi_pt(np_loc),voi_pt(np_loc),woi_pt(np_loc))
      allocate (ip(np_loc),jp(np_loc),kp(np_loc))
      allocate (ipu(np_loc),jpv(np_loc),kpw(np_loc))
      allocate (up_pt(np_loc),vp_pt(np_loc),wp_pt(np_loc))
      allocate (Fpu(np_loc),Fpv(np_loc),Fpw(np_loc))

      if (np_loc.le.100) nt = 1
      if (np_loc.gt.100) nt = OMP_threads

      call OMP_SET_NUM_THREADS(nt)

      SELECT CASE (order)
            CASE (1)
                  m = 1 !1.5d0
            CASE (2)
                  m = 2 !2.5d0
            CASE (3)
                  m = 2 !2.d0
            CASE (4)
                  m = 2 !2.5d0
            CASE (5)
                  m = 1 !1.5d0
            CASE (6)
                  m = 2 !2.d0
      end select

!loop in domains
      do ib=1,nbp

            Vcell = dom(ib)%dx*dom(ib)%dy*dom(ib)%dz  

!computational domain limits (one-axis index)   
            is = dom(ib)%isp
            ie = dom(ib)%iep
            js = dom(ib)%jsp
            je = dom(ib)%jep
            ks = dom(ib)%ksp                             
            ke = dom(ib)%kep

!loop in particles
!$OMP       PARALLEL DEFAULT (SHARED), PRIVATE(i,j,k,l,
!$OMP&      iballs_u,iballe_u,jballs_u,jballe_u,kballs_u,kballe_u,
!$OMP&      iballs_v,iballe_v,jballs_v,jballe_v,kballs_v,kballe_v,
!$OMP&      iballs_w,iballe_w,jballs_w,jballe_w,kballs_w,kballe_w,
!$OMP&      REp,rx,ry,rz,Vp,delta,gamma_p,
!$OMP&      a,b,c,ao,bo,co,Cd,wx,wy,wz,
!$OMP&      dwdy,dvdz,dudz,dvdx,dudy,dwdx,
!$OMP&      fcol_n,fcol_t,mu_f,deltap,
!$OMP&      k_n,k_t,theta_col,mp,
!$OMP&      lambda_w,lambda_u,lambda_v) 

!$OMP DO SCHEDULE (DYNAMIC,1)
      do l=1,np_loc

      IF (id(l).eq.dom_id(ib)) then                                     !particle belongs to THIS block

      Vp = 3.1416*dp_loc(l)**3.d0/6.d0

      ip(l)=INT((xp_loc(l)-dom(ib)%x(is-1)-1.d-12)/dom(ib)%dx)+1+pl
      jp(l)=INT((yp_loc(l)-dom(ib)%y(js-1)-1.d-12)/dom(ib)%dy)+1+pl
      kp(l)=INT((zp_loc(l)-dom(ib)%z(ks-1)-1.d-12)/dom(ib)%dz)+1+pl

!     write(myrank+700,*)'======================================='
!           write(myrank+700,*) 'proc and dom:',myrank,'->',dom_id(ib)
!           write(myrank+700,*) 'tstep:',itime
!           write(myrank+700,*)'ip',ip(l),jp(l),kp(l)

!     if (LENERGY) then
!           dom(ib)%dens(ip(l),jp(l),kp(l)) = 
!     &999.8/(1.+0.000088*(dom(ib)%T(ip(l),jp(l),kp(l))+20.))
!           dom(ib)%mu(ip(l),jp(l),kp(l)) = 
!     &2.414d-5*10.d0**(-25.2/(dom(ib)%T(ip(l),jp(l),kp(l))+20.-413.d0))

!     Re=dom(ib)%dens(ip(l),jp(l),kp(l))/dom(ib)%mu(ip(l),jp(l),kp(l))
!     endif


!locate the u,v and w nodes

      if (xp_loc(l).gt.dom(ib)%xc(ip(l))) then

      ipu(l) = ip(l)
!     ipux(l) = ip(l) - 1

      elseif (xp_loc(l).le.dom(ib)%xc(ip(l))) then

      ipu(l) = ip(l) - 1
!     ipux(l) = ip(l)

      endif

      if (yp_loc(l).gt.dom(ib)%yc(jp(l))) then

      jpv(l) = jp(l)
!     jpvy(l) = jp(l) - 1

      elseif (yp_loc(l).le.dom(ib)%yc(jp(l))) then

      jpv(l) = jp(l) - 1
!     jpvy(l) = jp(l)

      end if

      if (zp_loc(l).gt.dom(ib)%zc(kp(l))) then

      kpw(l) = kp(l)
!     kpwz(l) = kp(l) - 1

      elseif (zp_loc(l).le.dom(ib)%zc(kp(l))) then

      kpw(l) = kp(l) - 1
!     kpwz(l) = kp(l)

      end if            

!           write(myrank+700,*)'ipu',ipu(l),jpv(l),kpw(l)

      rx = max(dp_loc(l),dom(ib)%dx)
      ry = max(dp_loc(l),dom(ib)%dy)
      rz = max(dp_loc(l),dom(ib)%dz)

      !Ball

      IF (order.eq.3.or.order.eq.6) then
      if (ipu(l).eq.ip(l)) then
            iballs_u = ipu(l) - 1 * NINT(rx/dom(ib)%dx)
            iballe_u = ipu(l) + m * NINT(rx/dom(ib)%dx)
            iballs_v = ip(l) - 1 * NINT(rx/dom(ib)%dx)
            iballe_v = ip(l) + m * NINT(rx/dom(ib)%dx)
            iballs_w = ip(l) - 1 * NINT(rx/dom(ib)%dx)
            iballe_w = ip(l) + m * NINT(rx/dom(ib)%dx)
      else
            iballs_u = ipu(l) - m * NINT(rx/dom(ib)%dx)
            iballe_u = ipu(l) + 1 * NINT(rx/dom(ib)%dx)
            iballs_v = ip(l) - m * NINT(rx/dom(ib)%dx)
            iballe_v = ip(l) + 1 * NINT(rx/dom(ib)%dx)
            iballs_w = ip(l) - m * NINT(rx/dom(ib)%dx)
            iballe_w = ip(l) + 1 * NINT(rx/dom(ib)%dx)
      endif
      if (jpv(l).eq.jp(l)) then
            jballs_u = jp(l) - 1 * NINT(ry/dom(ib)%dy)
            jballe_u = jp(l) + m * NINT(ry/dom(ib)%dy)
            jballs_v = jpv(l) - 1 * NINT(ry/dom(ib)%dy)
            jballe_v = jpv(l) + m * NINT(ry/dom(ib)%dy)
            jballs_w = jp(l) - 1 * NINT(ry/dom(ib)%dy)
            jballe_w = jp(l) + m * NINT(ry/dom(ib)%dy)
      else
            jballs_u = jp(l) - m * NINT(ry/dom(ib)%dy)
            jballe_u = jp(l) + 1 * NINT(ry/dom(ib)%dy)
            jballs_v = jpv(l) - m * NINT(ry/dom(ib)%dy)
            jballe_v = jpv(l) + 1 * NINT(ry/dom(ib)%dy)
            jballs_w = jp(l) - m * NINT(ry/dom(ib)%dy)
            jballe_w = jp(l) + 1 * NINT(ry/dom(ib)%dy)
      endif
      if (kpw(l).eq.kp(l)) then
            kballs_u = kp(l) - 1 * NINT(rz/dom(ib)%dz)
            kballe_u = kp(l) + m * NINT(rz/dom(ib)%dz)
            kballs_v = kp(l) - 1 * NINT(rz/dom(ib)%dz)
            kballe_v = kp(l) + m * NINT(rz/dom(ib)%dz)
            kballs_w = kpw(l) - 1 * NINT(rz/dom(ib)%dz)
            kballe_w = kpw(l) + m * NINT(rz/dom(ib)%dz)
      else
            kballs_u = kp(l) - m * NINT(rz/dom(ib)%dz)
            kballe_u = kp(l) + 1 * NINT(rz/dom(ib)%dz)
            kballs_v = kp(l) - m * NINT(rz/dom(ib)%dz)
            kballe_v = kp(l) + 1 * NINT(rz/dom(ib)%dz)
            kballs_w = kpw(l) - m * NINT(rz/dom(ib)%dz)
            kballe_w = kpw(l) + 1 * NINT(rz/dom(ib)%dz)
      endif
      ELSE  
            iballs_u = ipu(l) - m * NINT(rx/dom(ib)%dx)
            iballe_u = ipu(l) + m * NINT(rx/dom(ib)%dx)
            jballs_u = jp(l) - m * NINT(ry/dom(ib)%dy)
            jballe_u = jp(l) + m * NINT(ry/dom(ib)%dy)
            kballs_u = kp(l) - m * NINT(rz/dom(ib)%dz)
            kballe_u = kp(l) + m * NINT(rz/dom(ib)%dz)

            iballs_v = ip(l) - m * NINT(rx/dom(ib)%dx)
            iballe_v = ip(l) + m * NINT(rx/dom(ib)%dx)
            jballs_v = jpv(l) - m * NINT(ry/dom(ib)%dy)
            jballe_v = jpv(l) + m * NINT(ry/dom(ib)%dy)
            kballs_v = kp(l) - m * NINT(rz/dom(ib)%dz)
            kballe_v = kp(l) + m * NINT(rz/dom(ib)%dz)

            iballs_w = ip(l) - m * NINT(rx/dom(ib)%dx)
            iballe_w = ip(l) + m * NINT(rx/dom(ib)%dx)
            jballs_w = jp(l) - m * NINT(ry/dom(ib)%dy)
            jballe_w = jp(l) + m * NINT(ry/dom(ib)%dy)
            kballs_w = kpw(l) - m * NINT(rz/dom(ib)%dz)
            kballe_w = kpw(l) + m * NINT(rz/dom(ib)%dz)
      ENDIF

      iballs_u = max(iballs_u,1)
      iballe_u = min(iballe_u,dom(ib)%ttc_i)
      jballs_u = max(jballs_u,1)
      jballe_u = min(jballe_u,dom(ib)%ttc_j)
      kballs_u = max(kballs_u,1)
      kballe_u = min(kballe_u,dom(ib)%ttc_k)
      iballs_v = max(iballs_v,1)
      iballe_v = min(iballe_v,dom(ib)%ttc_i)
      jballs_v = max(jballs_v,1)
      jballe_v = min(jballe_v,dom(ib)%ttc_j)
      kballs_v = max(kballs_v,1)
      kballe_v = min(kballe_v,dom(ib)%ttc_k)
      iballs_w = max(iballs_w,1)
      iballe_w = min(iballe_w,dom(ib)%ttc_i)
      jballs_w = max(jballs_w,1)
      jballe_w = min(jballe_w,dom(ib)%ttc_j)
      kballs_w = max(kballs_w,1)
      kballe_w = min(kballe_w,dom(ib)%ttc_k)

!           write(myrank+700,*)'ip_u',iballs_u,iballe_u
!           write(myrank+700,*)'ip_w',iballs_w,iballe_w
!           write(myrank+700,*)'kp_u',kballs_u,kballe_u
!           write(myrank+700,*)'kp_w',kballs_w,kballe_w


!     if (m.ne.2.d0) then
!     Vball = (iballe-iballs+1)*(jballe-jballs+1)*
!     &       (kballe-kballs+1)*Vcell
!     else  
!     Vball = (iballe-iballs)*(jballe-jballs)*
!     &       (kballe-kballs)*Vcell
!     endif

            uoi_pt(l) = 0.d0
            voi_pt(l) = 0.d0
            woi_pt(l) = 0.d0

      do i=iballs_u,iballe_u 
      do j=jballs_u,jballe_u 
      do k=kballs_u,kballe_u

            uoi_pt(l) = uoi_pt(l) + dom(ib)%uoo(i,j,k)*
     &      dh(rx,ry,rz,dom(ib)%x(i),dom(ib)%yc(j)
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

      enddo ; enddo ; enddo

      do i=iballs_v,iballe_v 
      do j=jballs_v,jballe_v 
      do k=kballs_v,kballe_v

            voi_pt(l) = voi_pt(l) + dom(ib)%voo(i,j,k)*
     &      dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%y(j)
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

      enddo ; enddo ; enddo

      do i=iballs_w,iballe_w 
      do j=jballs_w,jballe_w 
      do k=kballs_w,kballe_w

            woi_pt(l) = woi_pt(l) + dom(ib)%woo(i,j,k)*
     &      dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%yc(j)
     &      ,dom(ib)%z(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

      enddo ; enddo ; enddo

!           write(myrank+700,*)'uoi',uoi_pt(l),voi_pt(l),woi_pt(l)

            up_pt(l) = uop_loc(l)
            vp_pt(l) = vop_loc(l)
            wp_pt(l) = wop_loc(l)
      
            ui_pt(l) = 0.d0
            vi_pt(l) = 0.d0
            wi_pt(l) = 0.d0

      do i=iballs_u,iballe_u 
      do j=jballs_u,jballe_u 
      do k=kballs_u,kballe_u

            delta = dh(rx,ry,rz,dom(ib)%x(i),dom(ib)%yc(j)
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            ui_pt(l) = ui_pt(l) + dom(ib)%ustar(i,j,k) * delta

      enddo ; enddo ; enddo

      do i=iballs_v,iballe_v 
      do j=jballs_v,jballe_v 
      do k=kballs_v,kballe_v

            delta = dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%y(j)
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            vi_pt(l) = vi_pt(l) + dom(ib)%vstar(i,j,k) * delta

      enddo ; enddo ; enddo

      do i=iballs_w,iballe_w 
      do j=jballs_w,jballe_w 
      do k=kballs_w,kballe_w

            delta = dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%yc(j)
     &      ,dom(ib)%z(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            wi_pt(l) = wi_pt(l) + dom(ib)%wstar(i,j,k) * delta

      enddo ; enddo ; enddo

!           write(myrank+700,*)'ui',ui_pt(l),vi_pt(l),wi_pt(l)

      !Slip vel components 
      a = up_pt(l)-ui_pt(l)
      b = vp_pt(l)-vi_pt(l)
      c = wp_pt(l)-wi_pt(l)

!           write(myrank+700,*)'wslip',a,b,c

       REp = dp_loc(l)* (sqrt((uop_loc(l)-ui_pt(l))**2.d0+(vop_loc(l)
     &      -vi_pt(l))**2.d0+(wop_loc(l)-wi_pt(l))**2.d0))/(1.d0/Re)

        if (REp.le.800) Cd = 24.d0*(1.d0+0.15d0*(REp**0.687d0))/REp
        if (REp.gt.800) Cd = 0.44d0

      !Vorticity calculation  
      dudy = 0.0
        do i=iballs_u,iballe_u
        do j=jballs_u,jballe_u
        do k=kballs_u,kballe_u

          ddelta = ddh(rx,ry,rz,dom(ib)%x(i),dom(ib)%yc(j)
     &  ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order,2)

          dudy = dudy + dom(ib)%uoo(i,j,k)*ddelta

        end do ; end do ; end do


        dudz = 0.0
        do i=iballs_u,iballe_u
        do j=jballs_u,jballe_u
        do k=kballs_u,kballe_u

          ddelta = ddh(rx,ry,rz,dom(ib)%x(i),dom(ib)%yc(j)
     &  ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order,3)

          dudz = dudz + dom(ib)%uoo(i,j,k)*ddelta

        end do ; end do ; end do


        dvdx = 0.0
        do i=iballs_v,iballe_v
        do j=jballs_v,jballe_v
        do k=kballs_v,kballe_v

          ddelta = ddh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%y(j)
     &  ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order,1)

          dvdx = dvdx + dom(ib)%voo(i,j,k)*ddelta

        end do ; end do ; end do


        dvdz = 0.0
        do i=iballs_v,iballe_v
        do j=jballs_v,jballe_v
        do k=kballs_v,kballe_v

          ddelta = ddh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%y(j)
     &  ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order,3)

          dvdz = dvdz + dom(ib)%voo(i,j,k)*ddelta

        end do ; end do ; end do


        dwdx = 0.0
        do i=iballs_w,iballe_w
        do j=jballs_w,jballe_w
        do k=kballs_w,kballe_w

          ddelta = ddh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%yc(j)
     &  ,dom(ib)%z(k),xp_loc(l),yp_loc(l),zp_loc(l),order,1)

          dwdx = dwdx + dom(ib)%woo(i,j,k)*ddelta

        end do ; end do ; end do


        dwdy = 0.0
        do i=iballs_w,iballe_w
        do j=jballs_w,jballe_w
        do k=kballs_w,kballe_w

          ddelta = ddh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%yc(j)
     &  ,dom(ib)%z(k),xp_loc(l),yp_loc(l),zp_loc(l),order,2)

          dwdy = dwdy + dom(ib)%woo(i,j,k)*ddelta

        end do ; end do ; end do

        wx = dwdy-dvdz
        wy = dudz-dwdx
        wz = dvdx-dudy


!      up_pt(l) = uop_loc(l) + dt * (3.0d0*((ui_pt(l)-uoi_pt(l))/dt)    !Buoyancy, stress
!     &  -(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*a  !Added Mass and drag
!     &  -2.0d0*0.53d0*(b*wz-c*wy))                                           !Lift


!      vp_pt(l) = vop_loc(l) + dt* (3.0d0*((vi_pt(l)-voi_pt(l))/dt)
!     &  -(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*b
!     &  -2.0d0*0.53d0*(c*wx-a*wz))


!      wp_pt(l) = wop_loc(l) + dt* (2.0d0*9.81d0+3.0d0*
!     &     ((wi_pt(l)-woi_pt(l))/dt)     
!     &-(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*c          
!     &-2.0d0*0.53d0*(a*wy-b*wx))

      if (LENERGY.or.LSTRA) then                             !variable density form
      gamma_p=rhop_loc(l)/dom(ib)%dens(ip(l),jp(l),kp(l))	! variable density
      else
      gamma_p=rhop_loc(l)/dens                        ! constant density
      endif

      if ((dp_loc(l)).lt.0.00001) then !Particles with dp<10um treated as passive Aleks 05/2022
            up_pt(l) = ui_pt(l)
            vp_pt(l) = vi_pt(l)
            wp_pt(l) = wi_pt(l)
      else
      up_pt(l) = uop_loc(l) + dt * 
     &      (((1.+0.5)/(gamma_p+0.5))*((ui_pt(l)-uoi_pt(l))/dt)   
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*a 
     &      -(1./(gamma_p+0.5))*0.53d0*(b*wz-c*wy))                                             


      vp_pt(l) = vop_loc(l) + dt* 
     &      (((1.+0.5)/(gamma_p+0.5))*((vi_pt(l)-voi_pt(l))/dt)
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*b
     &      -(1./(gamma_p+0.5))*0.53d0*(c*wx-a*wz))


      wp_pt(l) = wop_loc(l) + dt* 
     &      (((1.-gamma_p)/(gamma_p+0.5))*9.81d0+                       !Buoyancy
     &      ((1.+0.5)/(gamma_p+0.5))*((wi_pt(l)-woi_pt(l))/dt)          !Fluid stress
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))                    !Added Mass and drag
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*c                         !Added Mass and drag    
     &      -(1./(gamma_p+0.5))*0.53d0*(a*wy-b*wx))   
      endif                  !Lift


!           write(myrank+700,*)'up',up_pt(l),vp_pt(l),wp_pt(l)


      IF (Lcolwall) THEN !call collision_walls(l,ib)       !updating particle velocities based on collisions with walls

            mu_f=9.2d-2

            !1.Define force range

            lambda_w=0.75*wp_pt(l)*dt
            lambda_u=0.75*up_pt(l)*dt  
            lambda_v=0.75*vp_pt(l)*dt
            
            !2. Spring stiffness

            
            k_n=1.72d7
            k_t=1.48d7  
            
            !3. Damping

            e_col=1.d0
            mp=rhop_loc(l)*(4/3)*3.1416*(0.5*dp_loc(l))**3
            theta_col=-2*alog(e_col)*(mp*k_n)**0.5/
     &      (3.1416**2+(alog(e_col))**2)
            
! ----------------------- collisions with bottom wall ----------------------------------                          
            if (zp_loc(l).lt.lambda_w+0.5*dp_loc(l)) then
            
            !a. overlap
            deltap=max((zp_loc(l)-dp_loc(l)/2)-zst,0.d0)
            !b. normal force
            fcol_n=-k_n*deltap-theta_col*wp_pt(l)
            
            wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
            
            !c. tangential force
            fcol_t=mu_f*fcol_n
            if (bc_b.ne.3) then                 !slip condition
                  up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                  vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
            endif 
            !write (6,*)l,wp_pt(l),zp_loc(l),fcol_n,fcol_t
            
            endif 
! ----------------------- collisions with top wall ----------------------------------                          
            if (zp_loc(l).gt.zen-lambda_w+0.5*dp_loc(l)) then
            
                  !a. overlap
                  deltap=max(zp_loc(l)-zen+0.5*dp_loc(l),0.d0) 
                  !b. normal force
                  fcol_n=-k_n*deltap-theta_col*wp_pt(l)
                  
                  wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
                  
                  !c. tangential force
                  fcol_t=mu_f*fcol_n
                  
                  if (bc_t.ne.3) then                 !slip condition
                        up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                        vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
                  endif 
                  !write (6,*)l,wp_pt(l),zp_loc(l),fcol_n,fcol_t
                  
                  endif 
! ----------------------- collisions with bottom wall ----------------------------------                          
            if (zp_loc(l).lt.lambda_w+0.5*dp_loc(l)) then
            
            !a. overlap
            deltap=max((zp_loc(l)-dp_loc(l)/2)-zst,0.d0)
            !b. normal force
            fcol_n=-k_n*deltap-theta_col*wp_pt(l)
            
            wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
            
            !c. tangential force
            fcol_t=mu_f*fcol_n
            if (bc_b.ne.3) then                 !slip condition
                  up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                  vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
            endif 
            !write (6,*)l,wp_pt(l),zp_loc(l),fcol_n,fcol_t
            
            endif 
! ----------------------- collisions with top wall ----------------------------------                          
            if (zp_loc(l).gt.zen-lambda_w+0.5*dp_loc(l)) then
            
                  !a. overlap
                  deltap=max(zp_loc(l)-zen+0.5*dp_loc(l),0.d0) 
                  !b. normal force
                  fcol_n=-k_n*deltap-theta_col*wp_pt(l)
                  
                  wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
                  
                  !c. tangential force
                  fcol_t=mu_f*fcol_n
                  
                  if (bc_t.ne.3) then                 !slip condition
                        up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                        vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
                  endif 
                  !write (6,*)l,wp_pt(l),zp_loc(l),fcol_n,fcol_t
                  
                  endif 
! ----------------------- collisions with bottom wall ----------------------------------                          
            if (zp_loc(l).lt.lambda_w+0.5*dp_loc(l)) then
            
            !a. overlap
            deltap=max((zp_loc(l)-dp_loc(l)/2)-zst,0.d0)
            !b. normal force
            fcol_n=-k_n*deltap-theta_col*wp_pt(l)
            
            wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
            
            !c. tangential force
            fcol_t=mu_f*fcol_n
            if (bc_b.ne.3) then                 !slip condition
                  up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                  vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
            endif       
            endif 
! ----------------------- collisions with top wall ----------------------------------                          
            if (zp_loc(l).gt.zen-lambda_w+0.5*dp_loc(l)) then
            
                  !a. overlap
                  deltap=max(zp_loc(l)-zen+0.5*dp_loc(l),0.d0) 
                  !b. normal force
                  fcol_n=-k_n*deltap-theta_col*wp_pt(l)
                  
                  wp_pt(l) = wp_pt(l) + dt*fcol_n/mp 
                  
                  !c. tangential force
                  fcol_t=mu_f*fcol_n
                  
                  if (bc_t.ne.3) then                 !slip condition
                        up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                        vp_pt(l) = vp_pt(l) + dt*fcol_t/mp 
                  endif 
            endif 
! ----------------------- collisions with south wall ----------------------------------                          
            if (yp_loc(l).lt.lambda_v+0.5*dp_loc(l)) then
            
            !a. overlap
            deltap=max((yp_loc(l)-dp_loc(l)/2)-yst,0.d0)
            !b. normal force
            fcol_n=-k_n*deltap-theta_col*vp_pt(l)
            
            vp_pt(l) = vp_pt(l) + dt*fcol_n/mp 
            
            !c. tangential force
            fcol_t=mu_f*fcol_n
            if (bc_s.ne.3) then                 !slip condition
                  up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                  wp_pt(l) = wp_pt(l) + dt*fcol_t/mp 
            endif             
            endif 
! ----------------------- collisions with top wall ----------------------------------                          
            if (yp_loc(l).gt.zen-lambda_v+0.5*dp_loc(l)) then
            
            !a. overlap
            deltap=max(yp_loc(l)-yen+0.5*dp_loc(l),0.d0) 
            !b. normal force
            fcol_n=-k_n*deltap-theta_col*vp_pt(l)
                  
            vp_pt(l) = vp_pt(l) + dt*fcol_n/mp 
                  
            !c. tangential force
            fcol_t=mu_f*fcol_n
                  
            if (bc_n.ne.3) then                 !slip condition
                  up_pt(l) = up_pt(l) + dt*fcol_t/mp 
                  wp_pt(l) = wp_pt(l) + dt*fcol_t/mp 
            endif 
            endif 
      ENDIF

      if ((dp_loc(l)).ge.0.00001) then !only do calcs if dp>=10um
      !Update slip velocity
      a = up_pt(l)-ui_pt(l)
      b = vp_pt(l)-vi_pt(l)
      c = wp_pt(l)-wi_pt(l)

      !Fluid stresses
!     Fsu(l) = dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*dp_loc(l)**3.d0*((ui_pt(l)-uoi_pt(l))/dt)/6.0d0
!     Fsv(l) = dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*dp_loc(l)**3.d0*((vi_pt(l)-voi_pt(l))/dt)/6.0d0
!     Fsw(l) = dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*dp_loc(l)**3.d0*((wi_pt(l)-woi_pt(l))/dt)/6.0d0

      !Added mass
!     Fau(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**3.d0)*(a-ao)/(12.0d0*dt)
!     Fav(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**3.d0)*(b-bo)/(12.0d0*dt)
!     Faw(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**3.d0)*(c-co)/(12.0d0*dt)

      !Drag
!     Fdu(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**2.d0)*Cd*(sqrt(a**2.d0+b**2.d0
!     &     +c**2.d0))*a/8.0d0
!     Fdv(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**2.d0)*Cd*(sqrt(a**2.d0+b**2.d0
!     &     +c**2.d0))*b/8.0d0
!     Fdw(l) = -dom(ib)%dens(ip(l),jp(l),kp(l))*3.14d0*(dp_loc(l)**2.d0)*Cd*(sqrt(a**2.d0+b**2.d0
!     &     +c**2.d0))*c/8.0d0

      
      !Lift
!      Flu(l) = -0.53d0*rho_p*3.14d0*(dp_loc(l)**3.d0)*(b*wz-c*wy)
!     &     /6.0d0
!      Flv(l) = -0.53d0*rho_p*3.14d0*(dp_loc(l)**3.d0)*(c*wx-a*wz)
!     &     /6.0d0
!      Flw(l) = -0.53d0*rho_p*3.14d0*(dp_loc(l)**3.d0)*(a*wy-b*wx)
!     &     /6.0d0

      !Interphase Force (bubble->liquid)

!     Fpu(l) = -(Fau(l) + Fdu(l) + Flu(l))
!     Fpv(l) = -(Fav(l) + Fdv(l) + Flv(l))
!     Fpw(l) = -(Faw(l) + Fdw(l) + Flw(l))

!     if (.not.DF) then
!
!      Fpu(l) = -(3.0d0*((ui_pt(l)-uoi_pt(l))/dt)     
!     &  -(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*a  
!     &  -2.0d0*0.53d0*(b*wz-c*wy))                   

!      Fpv(l) = -(3.0d0*((vi_pt(l)-voi_pt(l))/dt)
!     &  -(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*b  
!     &  -2.0d0*0.53d0*(c*wx-a*wz))

!      Fpw(l) = -(3.0d0*((wi_pt(l)-woi_pt(l))/dt)     
!     &-(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*c                
!     &-2.0d0*0.53d0*(a*wy-b*wx))

!     if (LENERGY) then
!      gamma_p=rho_p/dens
      Fpu(l) = -(((1.+0.5)/(gamma_p+0.5))*((ui_pt(l)-uoi_pt(l))/dt)     
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*a 
     &      -(1./(gamma_p+0.5))*0.53d0*(b*wz-c*wy))               

      Fpv(l) = -(((1.+0.5)/(gamma_p+0.5))*((vi_pt(l)-voi_pt(l))/dt)
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*b
     &      -(1./(gamma_p+0.5))*0.53d0*(c*wx-a*wz))

      !Fpw(l) =-(((1.-gamma_p)/(gamma_p+0.5))*9.81d0+                   !Buoyancy
      Fpw(l) =-(((1.+0.5)/(gamma_p+0.5))*((wi_pt(l)-woi_pt(l))/dt)            !Fluid stress
     &      -(3.0d0/(4.0d0*dp_loc(l)*(gamma_p+0.5)))                    !Added Mass and drag
     &      *Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*c                         !Added Mass and drag    
     &      -(1./(gamma_p+0.5))*0.53d0*(a*wy-b*wx))                     !Lift

!      Fpw(l) = -(2.0d0*9.81d0+3.0d0*((wi_pt(l)-woi_pt(l))/dt)    
!     &-(3.0d0/(2.0d0*dp_loc(l)))*Cd*sqrt(a**2.d0+b**2.d0+c**2.d0)*c                
!     &-2.0d0*0.53d0*(a*wy-b*wx))
!     endif

!     else

!     Fpu(l) = (a/dt) * (rho_p/dens)!- Fsu(l)/(Vp*dens)
!     Fpv(l) = (b/dt) * (rho_p/dens) !- Fsv(l)/(Vp*dens)
!     Fpw(l) = (c/dt) * (rho_p/dens) !- (Fsw(l) - Fgw(l))/(Vp*dens)
!     write(201,*) 'Fpw',Fpw(l)

!     endif

!           write(myrank+700,*)'Fp',Fpu(l),Fpv(l),Fpw(l)

!$OMP CRITICAL
      if (PSIcell) then

            dom(ib)%ustar(ipu(l),jp(l),kp(l)) = 
     &      dom(ib)%ustar(ipu(l),jp(l),kp(l)) + dt * alfapr * Fpu(l) *
     &      Vp/Vcell

            dom(ib)%vstar(ip(l),jpv(l),kp(l)) = 
     &      dom(ib)%vstar(ip(l),jpv(l),kp(l)) + dt * alfapr * Fpv(l) *
     &      Vp/Vcell

            dom(ib)%wstar(ip(l),jp(l),kpw(l)) = 
     &      dom(ib)%wstar(ip(l),jp(l),kpw(l)) + dt * alfapr * Fpw(l) *
     &      Vp/Vcell
      else
            do i=iballs_u,iballe_u 
            do j=jballs_u,jballe_u 
            do k=kballs_u,kballe_u

            delta = dh(rx,ry,rz,dom(ib)%x(i),dom(ib)%yc(j)                    
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            dom(ib)%ustar(i,j,k) = 
     &      dom(ib)%ustar(i,j,k) + dt * alfapr * Fpu(l) * delta *
     &      Vp/Vcell

            enddo ; enddo ; enddo


            do i=iballs_v,iballe_v 
            do j=jballs_v,jballe_v 
            do k=kballs_v,kballe_v

            delta = dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%y(j)
     &      ,dom(ib)%zc(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            dom(ib)%vstar(i,j,k) = 
     &      dom(ib)%vstar(i,j,k) + dt * alfapr * Fpv(l) * delta *
     &      Vp/Vcell

            enddo ; enddo ; enddo


            do i=iballs_w,iballe_w 
            do j=jballs_w,jballe_w 
            do k=kballs_w,kballe_w

            delta = dh(rx,ry,rz,dom(ib)%xc(i),dom(ib)%yc(j)
     &      ,dom(ib)%z(k),xp_loc(l),yp_loc(l),zp_loc(l),order)

            dom(ib)%wstar(i,j,k) = 
     &      dom(ib)%wstar(i,j,k) + dt * alfapr * Fpw(l) * delta *
     &      Vp/Vcell

            enddo ; enddo ; enddo

      endif

!$OMP END CRITICAL
      endif

!     Actualizar velocidad paso previo
            uop_loc(l) = up_pt(l)
            vop_loc(l) = vp_pt(l)
            wop_loc(l) = wp_pt(l)

!     Actualizar posicion de particula
            xp_loc(l)=xp_loc(l)+up_pt(l)*dt
            yp_loc(l)=yp_loc(l)+vp_pt(l)*dt
            zp_loc(l)=zp_loc(l)+wp_pt(l)*dt

!                 write(myrank+700,*)'xp_loc',xp_loc(l),yp_loc(l),zp_loc(l)

      ENDIF   !if the particle belongs to the block

      end do  !end of loop in particles
!$OMP ENDDO
!$OMP END PARALLEL


      end do      !end loop in domains


            deallocate (ui_pt,vi_pt,wi_pt,uoi_pt,voi_pt,woi_pt)
            deallocate (ip,jp,kp,ipu,jpv,kpw)
            deallocate (up_pt,vp_pt,wp_pt)
            deallocate (id)

      return
      end subroutine

!##########################################################################      
      subroutine final_LPT

!     sends backp(l) to master processor 

!##########################################################################

        use multidata
        use mpi
        use vars_pt

      implicit none

      integer,dimension(nprocs) :: strider
      integer s

      strider(1) = 0
      do s=2,nprocs
            strider(s) = ptsinproc(s-1) + strider(s-1)
      enddo

!     do s=1,nprocs
!                 write(myrank+800,*)'proc',s,'At',ntime
!                 write(myrank+800,*)'pts',ptsinproc(s)
!                 write(myrank+800,*)'strider',strider(s)
!     enddo

       call MPI_BARRIER (MPI_COMM_WORLD,ierr)

        call MPI_GATHERV(xp_loc,np_loc,MPI_DOUBLE_PRECISION,xp_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
        call MPI_GATHERV(yp_loc,np_loc,MPI_DOUBLE_PRECISION,yp_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 
        call MPI_GATHERV(zp_loc,np_loc,MPI_DOUBLE_PRECISION,zp_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 

        call MPI_GATHERV(uop_loc,np_loc,MPI_DOUBLE_PRECISION,uop_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 
        call MPI_GATHERV(vop_loc,np_loc,MPI_DOUBLE_PRECISION,vop_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
        call MPI_GATHERV(wop_loc,np_loc,MPI_DOUBLE_PRECISION,wop_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 

        call MPI_GATHERV(Fpu,np_loc,MPI_DOUBLE_PRECISION,Fu
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 
        call MPI_GATHERV(Fpv,np_loc,MPI_DOUBLE_PRECISION,Fv
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
        call MPI_GATHERV(Fpw,np_loc,MPI_DOUBLE_PRECISION,Fw
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr) 
        call MPI_GATHERV(dp_loc,np_loc,MPI_DOUBLE_PRECISION,dp_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
        call MPI_GATHERV(rhop_loc,np_loc,MPI_DOUBLE_PRECISION,rho_pt
     &,ptsinproc,strider,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)        
!     if (myrank.eq.0) then
!           do l=1,np
!                 write(myrank+800,*)'xp',xp_pt(l),yp_pt(l),zp_pt(l)
!           enddo
!     endif

      if (np_loc.gt.0) then
            deallocate (xp_loc,yp_loc,zp_loc)
            deallocate (uop_loc,vop_loc,wop_loc)
            deallocate (Fpu,Fpv,Fpw)
        deallocate (dp_loc,rhop_loc)
      endif

      return
      end subroutine



