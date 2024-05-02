!##########################################################################
      subroutine log_law(bound,ib)
!			Bruño Fraga Bugallo
!			Cardiff 2016
!			Schumman type boundary conditions
!##########################################################################
        use vars
        use multidata
        implicit none
        integer i,j,k,ib,bound,icont,tkmax
        double precision delta,n_x,n_y,n_z,vnor,vtan
        double precision uc,vc,wc,rrey,small
	  double precision aaa,bbb,const1,const2,const3,const4
	  double precision ustar,yplus,ustarold,conv,Ecte,kappa

        rrey  = 1.0/Re
        small = 1.e-30
	  kappa = 0.41
	  Ecte  = 9.0


        if (L_LSM)  rrey=dom(ib)%mu(i,j,k)/dom(ib)%dens(i,j,k)

	if (LENERGY) then
		dom(ib)%dens(i,j,k) = 
     &		999.8/(1.+0.000088*(dom(ib)%T(i,j,k)+20.))
		dom(ib)%mu(i,j,k) = 
     &		2.414d-5*10.d0**(-25.2/(dom(ib)%T(i,j,k)+20.-413.d0))
			rrey=dom(ib)%mu(i,j,k)/dom(ib)%dens(i,j,k)
	endif

	  SELECT CASE (bound)

	  CASE (1) 
              delta=dom(ib)%dx
              n_x=1.0
              n_y=0.0
              n_z=0.0
              i=dom(ib)%isp
              do k=dom(ib)%ksp-1,dom(ib)%kep+1
                 do j=dom(ib)%jsp-1,dom(ib)%jep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
                    vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_west.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_west.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10
		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.067d0) then
				dom(ib)%tauww(j,k)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauww(j,k)=ustar**2.0				!tau_1
			  	dom(ib)%tauww2(j,k)=dom(ib)%tauww(j,k)/vtan	!needs to be multiplied by a velocity component to provide tau_1j
			  endif
                 end do
              end do

	     CASE (2)
              delta=dom(ib)%dx
              n_x=-1.0
              n_y=0.0
              n_z=0.0
              i=dom(ib)%iep
              do k=dom(ib)%ksp-1,dom(ib)%kep+1
                 do j=dom(ib)%jsp-1,dom(ib)%jep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
                    vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_east.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_east.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10
		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.067d0) then
				dom(ib)%tauwe(j,k)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauwe(j,k)=ustar**2.0				!tau_1
			  	dom(ib)%tauwe2(j,k)=dom(ib)%tauwe(j,k)/vtan		!units m/s
			  endif
                 end do
              end do

           CASE(3)
              delta=dom(ib)%dy
              n_x=0.0
              n_y=1.0
              n_z=0.0
              j=dom(ib)%jsp

              do k=dom(ib)%ksp-1,dom(ib)%kep+1
                 do i=dom(ib)%isp-1,dom(ib)%iep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
                    vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_south.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_south.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10
		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.067d0) then
				dom(ib)%tauws(i,k)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauws(i,k)=ustar**2.0				!tau_1
			  	dom(ib)%tauws2(i,k)=dom(ib)%tauws(i,k)/vtan
			  endif
                 end do
              end do


           CASE (4)
              delta=dom(ib)%dy
              n_x=0.0
              n_y=-1.0
              n_z=0.0
              j=dom(ib)%jep
              do k=dom(ib)%ksp-1,dom(ib)%kep+1
                 do i=dom(ib)%isp-1,dom(ib)%iep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
                    vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_north.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_north.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10
		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.067d0) then
				dom(ib)%tauwn(i,k)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauwn(i,k)=ustar**2.0				!tau_1
			  	dom(ib)%tauwn2(i,k)=dom(ib)%tauwn(i,k)/vtan
			  endif
                 end do
              end do

           CASE (5)

              delta=dom(ib)%dz
              n_x=0.0
              n_y=0.0
              n_z=1.0
              k=dom(ib)%ksp

              do j=dom(ib)%jsp-1,dom(ib)%jep+1
                 do i=dom(ib)%isp-1,dom(ib)%iep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
			  vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_bottom.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_bottom.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10

		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
!        		if (dom_id(ib).eq.0.and.j.eq.20)  
!     &			write(6,*)ustar,yplus,delta,rrey,kappa
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.067d0) then
				dom(ib)%tauwb(i,j)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauwb(i,j)=ustar**2.0				!tau_1
			  	dom(ib)%tauwb2(i,j)=dom(ib)%tauwb(i,j)/vtan
				!dom(ib)%vis(i,j,k)=dom(ib)%tauwb2(i,j)*delta
			  endif
                 end do
              end do


           CASE (6)
              delta=dom(ib)%dz
              n_x=0.0
              n_y=0.0
              n_z=-1.0
              k=dom(ib)%kep
              do j=dom(ib)%jsp-1,dom(ib)%jep+1
                 do i=dom(ib)%isp-1,dom(ib)%iep+1
                    uc=0.5*(dom(ib)%u(i,j,k)+dom(ib)%u(i-1,j,k))
                    vc=0.5*(dom(ib)%v(i,j,k)+dom(ib)%v(i,j-1,k))
                    wc=0.5*(dom(ib)%w(i,j,k)+dom(ib)%w(i,j,k-1))
                    vnor=n_x*uc+n_y*vc+n_z*wc
                    vtan=sqrt(abs(uc*uc+vc*vc+wc*wc-vnor*vnor+small))
			if (dom(ib)%bc_top.eq.62) then				!rough wall
                  	ustar = kappa*vtan / log(30.d0*delta/fric)
                        yplus = delta*ustar/rrey
			elseif (dom(ib)%bc_top.eq.61) then				!smooth wall
				conv  = 1.
		            ustar = 1. 
		            icont = 0
		            tkmax = 10
		            do while ((conv.gt.(1.d-3)).and.
     &							(icont.lt.tkmax)) 
		               icont=icont+1
		               ustarold = ustar
		               yplus = max(1.0000001,delta*ustar/rrey)
		               ustar = vtan*kappa/log(Ecte*yplus)
		               conv  = abs((ustar-ustarold)/ustar)
		            enddo
		            if (icont.eq.tkmax) then 
		               print*,'USTAR DOESNT CONVERGE'
		               print*,'Tang. vel. = ',vtan 
		               stop
		            endif  
			endif
			  if (yplus.lt.11.63d0) then
				dom(ib)%tauwt(i,j)=rrey * vtan / delta
			  else
		 	  	dom(ib)%tauwt(i,j)=ustar**2.0				!tau_1
			  	dom(ib)%tauwt2(i,j)=dom(ib)%tauwt(i,j)/vtan
			  endif
                 end do
              end do

	  end select

        return
        end subroutine log_law
!##########################################################################
