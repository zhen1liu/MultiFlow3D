!#############################################################
      SUBROUTINE imb_square(numIB)
!#############################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB      
      double precision         :: nodexmin,nodexmax,nodeymin,nodeymax
      INTEGER      :: M,L,nin,njn,I,J,k,strlen2,c,nlay,maxc,clay
      CHARACTER*8  :: char_block2
      CHARACTER*31 :: gridfile

         write(char_block2,'(I8)') myrank
         strlen2=LEN(TRIM(ADJUSTL(char_block2)))
         char_block2=REPEAT('0',(3-strlen2))//TRIM(ADJUSTL(char_block2))
         gridfile='geom_Squ_'//TRIM(ADJUSTL(char_block2))//'.dat'
         open (unit=2, file=gridfile)
         write (2,*) 'variables="x","y","z"'
       
	  M=numIB   ;  maxnode = 0 ; L=0

         if (linfin(numIB).eq.1) then
           zini(M)=0.d0 ;   nlay=((zen-zst)/dzm(numIB))                             
         else if (linfin(numIB).eq.0) then
	   nlay=((zend(M)-zini(M))/dzm(numIB))               
         endif
         
         maxc=INT(R(M)/dxm(numIB))+1
         
         if(cmax(M).gt.maxc) cmax(M)=maxc
         
         
	DO K=1,nlay
	 if(linfin(M).eq.0) then   !This adds the lids of the finite
	  if (K.le.cmax(M) .or. K.ge.(nlay-cmax(M)+1)) then	 
	   clay=maxc
	  else 
	   clay=cmax(M)
	  endif
	 else
	   clay=cmax(M)
	 endif
	 
	 
	 Do c=1,clay	
 	 nodexmin = Cx(M)-R(M)+(c-1)*dxm(numIB)
 	 nodexmax = Cx(M)+R(M)-(c-1)*dxm(numIB)
         nodeymin = Cy(M)-R(M)+(c-1)*dym(numIB) 
         nodeymax = Cy(M)+R(M)-(c-1)*dym(numIB) 	
	
         nin=2*((R(M)-dxm(numIB)*(c-1))/dxm(numIB))+1 
         njn=2*((R(M)-dym(numIB)*(c-1))/dym(numIB))+1	 
                  
          do I=1,nin
            nodex(M,L)=nodexmin+dxm(numIB)*(I-1)
            nodey(M,L)=nodeymin
            nodez(M,L)=zini(M)+dzm(numIB)*(K-1)            
            L=L+1
          enddo
          do J=2,njn
            nodex(M,L)=nodexmax
            nodey(M,L)=nodeymin+dym(numIB)*(J-1)
            nodez(M,L)=zini(M)+dzm(numIB)*(K-1)                         
            L=L+1
          enddo
           do I=2,nin
            nodex(M,L)=nodexmax-dxm(numIB)*(I-1)
            nodey(M,L)=nodeymax
            nodez(M,L)=zini(M)+dzm(numIB)*(K-1)                         
            L=L+1
           enddo
           do J=2,njn-1
            nodex(M,L)=nodexmin
            nodey(M,L)=nodeymax-dym(numIB)*(J-1)
            nodez(M,L)=zini(M)+dzm(numIB)*(K-1)                         
            L=L+1
           enddo         
          Enddo
         ENDDO
         
         nodes(M)=L-1
         maxnode = max(maxnode,nodes(M))        
         
         Do L = 1,nodes(M)
            write (2,89) nodex(M,L),nodey(M,L),nodez(M,L)        
         End do  

      close (2)

   89 FORMAT (3e20.5)

      RETURN
      end
!######################################################################
      SUBROUTINE imb_cylinder(numIB)
!######################################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB
      double precision         :: thc,PI,Rtemp(1000),zccos,zcsin
      INTEGER      ::M,L,I,K,c,ctot,nlay,maxc,strlen2,nodes_percyl(1000)
      CHARACTER*8  :: char_block2
      CHARACTER*31 :: gridfile

         PI = 4.D0*DATAN(1.D0)       

         write(char_block2,'(I8)') numIB
         strlen2=LEN(TRIM(ADJUSTL(char_block2)))
         char_block2=REPEAT('0',(3-strlen2))//TRIM(ADJUSTL(char_block2))
         gridfile='geom_Cyl_'//TRIM(ADJUSTL(char_block2))//'.dat'
         open (unit=2, file=gridfile)
         write (2,*) 'variables="x","y","z"'

	 maxnode = 0; nodes_percyl = 0       

	 M=numIB   
	 Rtemp = R(M); nodes(M) = 0; c =1           
                    
         maxc=INT(R(M)/dxm(numIB))+1         
         if(cmax(M).gt.maxc) cmax(M)=maxc                 

            Do while (Rtemp(c).ge.0.d0 .and. c.le.maxc) 
               IF (c.eq.1) then
                nodes(M) = nodes(M) + NINT(2.d0*PI*Rtemp(c)/dxm(numIB))
                nodes_percyl(c) =     NINT(2.d0*PI*Rtemp(c)/dxm(numIB))
               else
                nodes(M) = nodes(M) +
     & 		NINT(2.d0*PI*Rtemp(c)/(dxm(numIB)))
                nodes_percyl(c)=NINT(2.0*PI*Rtemp(c)/(dxm(numIB)))
               end if
              IF (Rtemp(c).eq.0.d0) nodes(M)        = nodes(M) + 1
              IF (Rtemp(c).eq.0.d0) nodes_percyl(c) = 1
              c = c + 1
              Rtemp(c) = Rtemp(c-1) - dxm(numIB)                
           End do

           ctot = c - 1  
           
           if (linfin(M).eq.1) then
             zini(M)=zst ;   nlay=((zen-zst)/dzm(numIB))                             
           endif
           if (linfin(M).eq.0) then
	     nlay=((zend(M)-zini(M))/dzm(numIB))!-1               
           endif

	  L=1
	  Do K=1,nlay
		 if(linfin(M).eq.0) then   !This adds the lids of the finite
		  if (K.le.cmax(M) .or. K.ge.(nlay-cmax(M)+1)) then	 
		   ctot=maxc
		  else 
		   ctot=cmax(M)
		  endif
		 else
		   ctot=cmax(M)
		endif
           Do c = 1,ctot
            thc = 2.d0*PI/nodes_percyl(c)
             Do I = 1,nodes_percyl(c)
	      zccos= cos(2.d0*PI*(I-1)/nodes_percyl(c)+thc)
	      zcsin= sin(2.d0*PI*(I-1)/nodes_percyl(c)+thc)
	      nodex(M,L)= Cx(M) + Rtemp(c)*zccos
              nodey(M,L)= Cy(M) + Rtemp(c)*zcsin
              nodez(M,L)= zini(M)+dzm(numIB)*(K-1)
              write(2,89) nodex(M,L),nodey(M,L),nodez(M,L)
              L = L + 1     
             End do  
            End do
          End Do
          
                     
           nodes(M) = L-1
           maxnode = max(maxnode,nodes(M))          

      close (2)
      
           
        write (6,*) ' '
        write (6,87) '** CYLINDER',numIB,',  # of nodes  :',nodes(numIB)
            
   87 FORMAT (a,i2,a,i5)
   89 FORMAT (3e20.5)

      RETURN
      end
!#############################################################
      SUBROUTINE imb_cube(numIB)
!#############################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB
      double precision :: nodexmin,nodexmax,nodeymin
      double precision :: nodeymax,nodezmin,nodezmax
      INTEGER      :: M,L,nin,njn,nkn,I,J,k,strlen2
      CHARACTER*8  :: char_block2
      CHARACTER*31 :: gridfile

         write(char_block2,'(I8)') myrank
         strlen2=LEN(TRIM(ADJUSTL(char_block2)))
         char_block2=REPEAT('0',(3-strlen2))//TRIM(ADJUSTL(char_block2))
         gridfile='geom_Cube_'//TRIM(ADJUSTL(char_block2))//'.dat'
         open (unit=2, file=gridfile)
         write (2,*) 'variables="x","y","z"'
      
         maxnode = 0
! -------------------------------------------------
	 M=numIB
 	
         nodexmin=Cx(M)-R(M); nodexmax=Cx(M)+R(M)
         nodeymin=Cy(M)-R(M); nodeymax=Cy(M)+R(M)
         nodezmin=Cz(M)-R(M); nodezmax=Cz(M)+R(M)

         nin =2.d0*R(M)/dxm(numIB)
         if(abs(nin-2.0*R(M)/dxm(numIB)).ge.0.999999999)
     & then
            nin=nin+1
            print*,'absurd-x!!!!!'
         end if
         nin=nin+1

         njn =2.d0*R(M)/dym(numIB)
         if(abs(njn-2.0*R(M)/dym(numIB)).ge.0.999999999)
     & then
            njn=njn+1
            print*,'absurd-y!!!!!'
         end if
         njn=njn+1

         nkn =2.d0*R(M)/dzm(numIB)
         if(abs(nkn-2.0*R(M)/dzm(numIB)).ge.0.999999999)
     & then
            nkn=nkn+1
            print*,'absurd-y!!!!!'
         end if
         nkn=nkn+1

         nodes(M)= nkn * nin * njn
         maxnode = max(maxnode,nodes(M))

        Do k = 1,nkn
         Do I = 1, nin
          Do J = 1, njn 
             L = (k-1)*nin*njn + (I-1)*njn + J
              IF (I.eq.1) THEN 
               nodex(M,L) = nodexmin
              else IF (I.eq.nin) THEN 
               nodex(M,L) = nodexmax
              ELSE
               nodex(M,L) = nodex(M,L-njn) + dxm(numIB)
              END IF
              IF (J.eq.1) THEN 
               nodey(M,L) = nodeymin
              else IF (J.eq.njn) THEN 
               nodey(M,L) = nodeymax
              ELSE
               nodey(M,L) = nodey(M,L-1) + dym(numIB)
              END IF
              IF (K.eq.1) THEN 
               nodez(M,L) = nodezmin
              else IF (K.eq.nkn) THEN 
               nodez(M,L) = nodezmax
              ELSE
               nodez(M,L) = nodez(M,L-nin*njn) + dzm(numIB)
              END IF
          End do         
         End do
        end do
         Do L = 1,nodes(M)
            write (2,89) nodex(M,L),nodey(M,L),nodez(M,L)        
         End do  

      close (2)

   88 FORMAT (i5)
   89 FORMAT (3e20.5)

      RETURN
      end
!######################################################################
      SUBROUTINE imb_sphere(numIB)
!######################################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB
      double precision         :: thc,PI,thz(80),zccos,zcsin
      INTEGER      :: M,L,K,c
      INTEGER      :: strlen2,nzr(80),izr,maxnzr
      CHARACTER*8  :: char_block2
      CHARACTER*31 :: gridfile
      double precision,allocatable,dimension (:,:) :: ztemp_layer
      double precision,allocatable,dimension (:,:,:) :: Rtemp_layer      
      INTEGER,allocatable,dimension (:,:) :: ctot_layer,nodes_layer
      INTEGER,allocatable,dimension (:,:,:) :: nodes_percyl_layer


      PI = 4.D0*DATAN(1.D0)

         write(char_block2,'(I8)') myrank
         strlen2=LEN(TRIM(ADJUSTL(char_block2)))
         char_block2=REPEAT('0',(3-strlen2))//TRIM(ADJUSTL(char_block2))
         gridfile='geom_Sphere_'//TRIM(ADJUSTL(char_block2))//'.dat'
         open (unit=2, file=gridfile)

	maxnzr=0 ;   maxnode = 0
	M=numIB
	
	nzr(M) = nint((2.d0*PI*R(M)/2.d0)/dxm(numIB)) !Number of planes
	thz(M) = PI/(nzr(M))
	maxnzr=max(maxnzr,nzr(M))
        write (2,*) 'variables="x","y","z"'

	allocate (ztemp_layer(L,maxnzr),ctot_layer(L,maxnzr))
        allocate (nodes_layer(L,10000),Rtemp_layer(L,maxnzr,100))
	allocate (nodes_percyl_layer(L,maxnzr,100))

         nodes_percyl_layer = 0 ;    nodes_layer = 0 ;nodes_layer=0
                  
	  M=numIB
	     nodes(M) = 0
	     
	 do izr = 1,nzr(M)	 
	      c =1
         if (izr.eq.1) then
	   Rtemp_layer(M,izr,c) = 0.d0
         else
	   Rtemp_layer(M,izr,c) = R(M)*cos(thz(M)*(izr-1)-(PI/2.d0))
	   ztemp_layer(M,izr) = R(M)*sin(thz(M)*(izr-1)-(PI/2.d0))+Cz(M)
         end if

	      do while (Rtemp_layer(M,izr,c).ge.0.)		!gt!!!
                nodes_layer(M,izr) = nodes_layer(M,izr) + 
     &  NINT(2.0*PI*Rtemp_layer(M,izr,c)/dxm(numIB))
                nodes_percyl_layer(M,izr,c) = 
     &  NINT(2.0*PI*Rtemp_layer(M,izr,c)/dxm(numIB))
               if (Rtemp_layer(M,izr,c).eq.0.) then
                nodes_layer(M,izr) = nodes_layer(M,izr) + 1
                nodes_percyl_layer(M,izr,c) = 1
               end if
               c = c + 1
               Rtemp_layer(M,izr,c) = Rtemp_layer(M,izr,c-1)- dxm(numIB)
               
             if(c.ge.cmax(M)) goto 555 
               
	      end do

555	CONTINUE
              ctot_layer(M,izr) = c - 1
	      if(ctot_layer(M,izr) .gt. 100) then
	      print*, 'allocate problem in Rtemp_layer'
	      end if
          end do      	    

	M=numIB
	 izr=1
	    K = 1
	 do while(izr.le.nzr(M))
	   do c = 1,ctot_layer(M,izr)
	    thc = 2.d0*PI/nodes_percyl_layer(M,izr,c)
	     do L = 1,nodes_percyl_layer(M,izr,c)
	      zccos = cos(2.d0*PI*(L-1)/nodes_percyl_layer(M,izr,c)+thc)
	      zcsin = sin(2.d0*PI*(L-1)/nodes_percyl_layer(M,izr,c)+thc)
              nodex(M,K) = Cx(M) + Rtemp_layer(M,izr,c)*zccos
	      nodey(M,K) = Cy(M) + Rtemp_layer(M,izr,c)*zcsin
	      nodez(M,K) = Cz(M) + R(M)*sin(thz(M)*(izr-1)-(PI/2.d0))
	      write(2,89) nodex(M,K), nodey(M,K), nodez(M,K)
               K = K + 1     
	     end do
	    end do
            izr = izr + 1     
          end do
 	      nodes(M) = K-1
  	      maxnode = max(maxnode,nodes(M))	          

	deallocate (ztemp_layer,ctot_layer,nodes_layer)
	deallocate (nodes_percyl_layer,Rtemp_layer)

      close (2)

   88 FORMAT (i15)
   89 FORMAT (3e20.6)

      RETURN
      end 
!#############################################################
      SUBROUTINE imb_file(numIB)
!#############################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB
      double precision       :: PI,angle
      INTEGER      :: L,nin,I,K,nlay,dummy,strlen
      CHARACTER*8  :: char_block2
      CHARACTER*31 :: gridfile
      double precision, ALLOCATABLE, DIMENSION (:) ::xfile,yfile,zfile

       PI = 4.D0*DATAN(1.D0)

         write(char_block2,'(I8)') numIB
         strlen=LEN(TRIM(ADJUSTL(char_block2)))
         char_block2=REPEAT('0',(3-strlen))//TRIM(ADJUSTL(char_block2))
         gridfile='geom_body_'//TRIM(ADJUSTL(char_block2))//'.dat'
         open (unit=2, file=gridfile)
!----      Load the file and proceed to interpolate     ----------
 	  open(unit=1, file=filepoints(numIB))
	   read(1,*)nin	!Mesh points	

	   select case(axis(numIB))			!Brunho2015
		CASE (1)
			allocate(yfile(nin),zfile(nin))
			    DO L=1,nin
				 read(1,*)yfile(L),zfile(L)
			    ENDDO
			close (1)
			maxnode=0  
			Cxor(numIB)=Cx(numIB) 
			Cyor(numIB)=Cy(numIB)
			Czor(numIB)=Cz(numIB)			           
           if (linfin(numIB).eq.1) then
             zini(numIB)=0.d0 ;   nlay=((xen-xst)/(dxm(numIB)))!-1                             
           else if (linfin(numIB).eq.0) then
	     nlay=((zend(numIB)-zini(numIB))/(dxm(numIB)))!-1               
           endif							
!			nlay=((xen-xst)/dxm)-1   !# of x-layers 
			nodes(numIB)=nin*nlay*imbnumber(numIB)
			maxnode = max(maxnode,nodes(numIB))
	  		K=1
	  		do L=1,nlay  
	   		 DO I=1,nin 
		 	  nodex(numIB,K)=zini(numIB)+dxm(numIB)*(L)
     &							-xaero(numIB)
			  nodey(numIB,K)=yfile(I) - yaero(numIB)
			  nodez(numIB,K)=zfile(I) - zaero(numIB)	 
	     		  K=K+1	 
	   		 ENDDO
	   		Enddo
		CASE (2)
			allocate(xfile(nin),zfile(nin))
			    DO L=1,nin
				 read(1,*)xfile(L),zfile(L)
			    ENDDO
			close (1)
			maxnode=0  
			Cxor(numIB)=Cx(numIB) 
			Cyor(numIB)=Cy(numIB)
			Czor(numIB)=Cz(numIB)
           if (linfin(numIB).eq.1) then
             zini(numIB)=0.d0 ;   nlay=((yen-yst)/dym(numIB))!-1                             
           else if (linfin(numIB).eq.0) then
	     nlay=((zend(numIB)-zini(numIB))/dym(numIB))!-1               
           endif			
!			nlay=((yen-yst)/dym(numIB))-1   !# of y-layers 
			nodes(numIB)=nin*nlay*imbnumber(numIB)
			 	maxnode = max(maxnode,nodes(numIB))
	  		K=1
	  		do L=1,nlay  
	   		 DO I=1,nin 
		 	  nodex(numIB,K)=xfile(I) - xaero(numIB)
			  nodey(numIB,K)=zini(numIB)+dym(numIB)*(L)
     &	-yaero(numIB)
			  nodez(numIB,K)=zfile(I) - zaero(numIB)  
	     		  K=K+1	 
	   		 ENDDO
	   		Enddo
		CASE (3)
			allocate(xfile(nin),yfile(nin))
			    DO L=1,nin
				 read(1,*)xfile(L),yfile(L)
			    ENDDO
			close (1)
			maxnode=0  
			Cxor(numIB)=Cx(numIB) 
			Cyor(numIB)=Cy(numIB)
			Czor(numIB)=Cz(numIB)
           if (linfin(numIB).eq.1) then
             zini(numIB)=0.d0 ;   nlay=((zen-zst)/dzm(numIB))!-1  !it was-1                          
           else if (linfin(numIB).eq.0) then
	     nlay=((zend(numIB)-zini(numIB))/dzm(numIB))!-1               
           endif
!			nlay=((zen-zst)/dzm)-1   !# of z-layers 
			nodes(numIB)=nin*nlay*imbnumber(numIB)
			maxnode = max(maxnode,nodes(numIB))
	  		K=1
	  		do L=1,nlay  
	   		 DO I=1,nin 
		 	  nodex(numIB,K)=xfile(I) - xaero(numIB)
			  nodey(numIB,K)=yfile(I) - yaero(numIB)
		 	  nodez(numIB,K)=zini(numIB)+dzm(numIB)*(L)
     &							-zaero(numIB)	 
	     		  K=K+1	 
	   		 ENDDO
	   		Enddo
		CASE (-1)
			write(6,*)'No extrusion of Body #',numIB
			allocate(xfile(nin),yfile(nin),zfile(nin))
			  DO L=1,nin
			   read(1,*)xfile(L),yfile(L),zfile(L)
			  ENDDO
			close (1)
			maxnode=0   ; nlay=1
			Cxor(numIB)=Cx(numIB) 
			Cyor(numIB)=Cy(numIB)
			Czor(numIB)=Cz(numIB)
			nodes(numIB)=nin*imbnumber(numIB)
			maxnode = max(maxnode,nodes(numIB))
	   		DO I=1,nin 
		 	  nodex(numIB,I)=xfile(I)! - xaero(numIB) 
			  nodey(numIB,I)=yfile(I)! - yaero(numIB)
			  nodez(numIB,I)=zfile(I)! - zaero(numIB)			  
	   		ENDDO
	end select
!	    DO K=1,nodes(numIB)
!		 delvol(numIB,K)=dom(ib)%dx*dom(ib)%dy*dom(ib)%dz*reddelta
!	    ENDDO 

	  DO I=1,nin
		if (nodex(numIB,I).lt.0.0) then
 		write(6,*)'APAMPAO, point',I,'is out of domain',nodex(numIB,I)
		elseif (nodex(numIB,I).le.1.d-10) then
		nodex(numIB,I)=1.d-10
		endif
		if (nodey(numIB,I).lt.0.0) then
 		write(6,*)'ERROR, point',I,'is out of domain',nodey(numIB,I)
		elseif (nodey(numIB,I).le.1.d-10) then
		nodey(numIB,I)=1.d-10
		endif
		if (nodez(numIB,I).lt.0.0) then
 		write(6,*)'ERROR, point',I,'is out of domain',nodez(numIB,I)
		elseif (nodez(numIB,I).le.1.d-10) then
		nodez(numIB,I)=1.d-10
		endif
	  ENDDO
	

	IF (imb_shape(numIB).eq.5 .and. turax(numIB).eq.1 .and.
     &   pitch(numIB).lt.0.000) then	 
	   angle=pitch(numIB)*PI/180.d0	   !Angle of attack in radians
	   do i=1,nin*nlay		   !Rotate the body.
		nodex(numIB,i)=nodex(numIB,i)*cos(angle)-
     &				nodey(numIB,i)*sin(angle)
		nodey(numIB,i)=nodex(numIB,i)*sin(angle)+
     &				nodey(numIB,i)*cos(angle)
		nodexlocal(numIB,i)=nodex(numIB,i)
		nodeylocal(numIB,i)=nodey(numIB,i)
		nodezlocal(numIB,i)=nodez(numIB,i)
	     enddo
	     do i=1,nin*nlay		!From local tu global coords
		nodex(numIB,i)=nodex(numIB,i)+Cxor(numIB)
		nodey(numIB,i)=nodey(numIB,i)+Cyor(numIB)
		nodez(numIB,i)=nodez(numIB,i)+Czor(numIB)
	    ENDDO
	 
	 ELSE
	  do i=1,nin*nlay		!Rotate the body.
		nodexlocal(numIB,i)=nodex(numIB,i)
		nodeylocal(numIB,i)=nodey(numIB,i)
		nodezlocal(numIB,i)=nodez(numIB,i)
		nodex(numIB,i)=nodex(numIB,i)+Cxor(numIB)
		nodey(numIB,i)=nodey(numIB,i)+Cyor(numIB)
		nodez(numIB,i)=nodez(numIB,i)+Czor(numIB)
	   enddo   	   	    
	ENDIF

	if(imb_shape(numIB).eq.5) call imb_number(numIB)
	if(imb_shape(numIB).ne.5) print*,'subroutine not finished'
       close(2)

   88 FORMAT (i5)
   89 FORMAT (3e25.5)
      RETURN
      end        
!#############################################################
      SUBROUTINE imb_number(numIB)
!#############################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      integer, intent (in) :: numIB
      INTEGER      :: I,K

	K=nodes(numIB)/imbnumber(numIB) !# of Lagrangians per unit

        write (6,*) ' '
        write (6,*) '**********   THE BODY ',numIB,' HAS : *******'
	write(6,*)'Total # ofnodes              :',nodes(numIB)
	write(6,*)'# of bodies                  :',imbnumber(numIB)
	IF(LSELFST(numIB))      write(6,*)'Turbine Self-Starting   :  YES'
	IF(.not.LSELFST(numIB)) write(6,*)'Turbine Self-Starting   :  NO'
	write(2,*)'variables="x","y","z"'
!-----------------	1- body      --------------------------------
	if (imbnumber(numIB).eq.1) then
	  do i=1,K
	   nodex(numIB,i) = nodex(numIB,i) 
	   nodey(numIB,i) = nodey(numIB,i)
	   nodez(numIB,i) = nodez(numIB,i) 	
	   write (2,89) nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)    
	  enddo
	endif
!-----------------	2- bodies      --------------------------------
      IF (imbnumber(numIB).eq.2) then
	 do i=1,K
	   nodex(numIB,i) = nodex(numIB,i) 
	   nodey(numIB,i) = nodey(numIB,i) + R(numIB)
	   nodez(numIB,i) = nodez(numIB,i) 		
	  write (2,89) nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)    
	 enddo
	 do i=1,K
	  nodex(numIB,K+i)=-nodexlocal(numIB,i) 
	  nodey(numIB,K+i)=-nodeylocal(numIB,i)
	  nodex(numIB,K+i)=nodex(numIB,K+i) + Cxor(numIB) 
	  nodey(numIB,K+i)=nodey(numIB,K+i)+Cyor(numIB)-R(numIB)
	  nodez(numIB,K+i)=nodez(numIB,i) 	 
         write (2,89) nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i) 
	 enddo
      ENDIF
!-----------------	3- bodies      --------------------------------
	IF (imbnumber(numIB).eq.3) then
	do i=1,K
	  nodex(numIB,i) = nodex(numIB,i) 
	  nodey(numIB,i) = nodey(numIB,i) + R(numIB) 
	  nodez(numIB,i) = nodez(numIB,i) 		
	  write (2,89) nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)  
	enddo
        do i=1,K
	  nodex(numIB,K+i)=nodexlocal(numIB,i)*(-0.5)-
     &                  nodeylocal(numIB,i)*(SQRT(3.)/2)
	  nodey(numIB,K+i)=nodexlocal(numIB,i)*(SQRT(3.)/2)+
     &                  nodeylocal(numIB,i)*(-0.5)
	  nodex(numIB,K+i)=nodex(numIB,K+i)+Cxor(numIB)-
     &			  R(numIB)*SQRT(3.)/2 
	  nodey(numIB,K+i)=nodey(numIB,K+i)+Cyor(numIB)-R(numIB)*0.5 
	  nodez(numIB,K+i)=nodez(numIB,i) 	 
         write (2,89) nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i) 
        enddo
        do i=1,K
	 nodex(numIB,2*K+i)=nodexlocal(numIB,i)*(-0.5)-
     &                     nodeylocal(numIB,i)*(-SQRT(3.)/2)
	 nodey(numIB,2*K+i)=nodexlocal(numIB,i)*(-SQRT(3.)/2)+
     &                     nodeylocal(numIB,i)*(-0.5)
	 nodex(numIB,2*K+i)=nodex(numIB,2*K+i)+Cxor(numIB)+
     &				R(numIB)*SQRT(3.)/2 
	 nodey(numIB,2*K+i)=nodey(numIB,2*K+i)+Cyor(numIB)-
     &				R(numIB)*0.5 
	 nodez(numIB,2*K+i)=nodez(numIB,i) 	 
         write (2,89) nodex(numIB,2*K+i),nodey(numIB,2*K+i)
     &   		,nodez(numIB,2*K+i) 
        enddo
       ENDIF
!-----------------	4- bodies      --------------------------------
	IF (imbnumber(numIB).eq.4) then
       do i=1,K
	nodex(numIB,i) = nodex(numIB,i)
	nodey(numIB,i) = nodey(numIB,i) + R(numIB)
	nodez(numIB,i) = nodez(numIB,i) 		
	write (2,89) nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)   
       enddo
        do i=1,K
          nodex(numIB,K+i)=-nodeylocal(numIB,i)
          nodey(numIB,K+i)=nodexlocal(numIB,i)
          nodex(numIB,K+i)=nodex(numIB,K+i)+Cxor(numIB)-R(numIB) 
          nodey(numIB,K+i)=nodey(numIB,K+i) + Cyor(numIB) 
	  nodez(numIB,K+i)=nodez(numIB,i) 	 
	 write (2,89) nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i) 
       enddo
        do i=1,K
          nodex(numIB,2*K+i)=-nodexlocal(numIB,i)
          nodey(numIB,2*K+i)=-nodeylocal(numIB,i)
          nodex(numIB,2*K+i)=nodex(numIB,2*K+i) + Cxor(numIB) 
          nodey(numIB,2*K+i)=nodey(numIB,2*K+i) + Cyor(numIB)-R(numIB)
	  nodez(numIB,2*K+i)=nodez(numIB,i) 	            
         write (2,89) nodex(numIB,2*K+i),nodey(numIB,2*K+i)
     &   		,nodez(numIB,2*K+i) 
       enddo
        do i=1,K
          nodex(numIB,3*K+i)=nodeylocal(numIB,i)
          nodey(numIB,3*K+i)=-nodexlocal(numIB,i)
          nodex(numIB,3*K+i)=nodex(numIB,3*K+i) + Cxor(numIB)+R(numIB) 
          nodey(numIB,3*K+i)=nodey(numIB,3*K+i) + Cyor(numIB)  
         write (2,89) nodex(numIB,3*K+i),nodey(numIB,3*K+i)
     &   		,nodez(numIB,3*K+i) 
       enddo
	ENDIF

   88 FORMAT (i5)
   89 FORMAT (3e25.5)

	RETURN
	END SUBROUTINE 
!#############################################################
      SUBROUTINE imb_moved(numIB)
!#############################################################
      use vars
      use multidata
      use imb
      use mpi
      implicit none
      INTEGER, intent(in) :: numIB
      double precision       :: PI
      INTEGER      :: L,I,K,strlen,Geom_Time1    
      CHARACTER*8  :: char_block
      CHARACTER*31 :: gridfile1

       PI = 4.D0*DATAN(1.D0)

      if (.NOT.LSELFST(K)) rads(numIB)=radsin(numIB)*CTIME

      IF (myrank.ne.master) RETURN

       Geom_Time1=301 ; 
       K=nodes(numIB)/imbnumber(numIB) !Nodes per body


	IF (turax(numIB).eq.1) then	! Vertical Axis Turbine
       do L=1,K
      nodexlocal(numIB,L)=-R0(numIB,L)*sin(rads(numIB)-alpha0(numIB,L))
      nodeylocal(numIB,L)= R0(numIB,L)*cos(rads(numIB)-alpha0(numIB,L))
       enddo  
!-----------------	1- body      --------------------------------
	IF (imbnumber(numIB).eq.1) then
         if (mod(itime,n_out).eq.0) then
           write(char_block,'(I8)') itime
           strlen=LEN(TRIM(ADJUSTL(char_block)))
           char_block=REPEAT('0',(6-strlen))//TRIM(ADJUSTL(char_block))
           gridfile1='Blade_Time_'//TRIM(ADJUSTL(char_block))//'.plt'
         open (unit=Geom_Time1, file=gridfile1)
	   write(Geom_Time1,*)'title = points'
	   write(Geom_Time1,*)'variables="x","y","z"'
	   write(Geom_Time1,*)
     &    'zone   ','i=  ',nodes(numIB),'DATAPACKING = POINT'
         endif
	  do i=1,K
		nodex(numIB,i) = nodexlocal(numIB,i) + Cxor(numIB)
		nodey(numIB,i) = nodeylocal(numIB,i) + Cyor(numIB)
   	    if (mod(itime,n_out).eq.0) then
	     write (Geom_Time1,89) 
     &		nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)   
    	    endif
	  enddo

	  if (mod(itime,n_out).eq.0)  close(Geom_Time1)
	ENDIF
!-----------------	2- bodies      --------------------------------
       IF (imbnumber(numIB).eq.2) then

         if (mod(itime,n_out).eq.0) then
           write(char_block,'(I8)') itime
           strlen=LEN(TRIM(ADJUSTL(char_block)))
           char_block=REPEAT('0',(6-strlen))//TRIM(ADJUSTL(char_block))
           gridfile1='Blade_Time_'//TRIM(ADJUSTL(char_block))//'.plt'
         open (unit=Geom_Time1, file=gridfile1)
	   write(Geom_Time1,*)'title = points'
	   write(Geom_Time1,*)'variables="x","y","z"'
	   write(Geom_Time1,*)
     &    'zone   ','i=  ',nodes(numIB),'DATAPACKING = POINT'
	 endif
	  do i=1,K
	        nodex(numIB,i) = nodexlocal(numIB,i) + Cxor(numIB)
	        nodey(numIB,i) = nodeylocal(numIB,i) + Cyor(numIB)
	    if (mod(itime,n_out).eq.0) then
	write(Geom_Time1,89)nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)    
	    endif
          enddo
          do i=1,K
                nodex(numIB,K+i)=-nodexlocal(numIB,i) + Cxor(numIB)
                nodey(numIB,K+i)=-nodeylocal(numIB,i) + Cyor(numIB)
	    if (mod(itime,n_out).eq.0) then        
                write (Geom_Time1,89)
     &		 nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i)   
	    endif
          enddo
	  if (mod(itime,n_out).eq.0)   close(Geom_Time1)
       ENDIF
!-----------------	3- bodies      --------------------------------
	IF (imbnumber(numIB).eq.3) then

         if (mod(itime,n_out).eq.0) then
           write(char_block,'(I8)') itime
           strlen=LEN(TRIM(ADJUSTL(char_block)))
           char_block=REPEAT('0',(6-strlen))//TRIM(ADJUSTL(char_block))
           gridfile1='Blade_Time_'//TRIM(ADJUSTL(char_block))//'.plt'
         open (unit=Geom_Time1, file=gridfile1)
	  write(Geom_Time1,*)'title = points'
	  write(Geom_Time1,*)'variables="x","y","z"'
	  write(Geom_Time1,*)
     &  	  'zone   ','i=  ',nodes(numIB),'DATAPACKING = POINT'
	 endif

   	 do i=1,K
		nodex(numIB,i) = nodexlocal(numIB,i) + Cxor(numIB)
		nodey(numIB,i) = nodeylocal(numIB,i) + Cyor(numIB)! + R(numIB)
           if (mod(itime,n_out).eq.0)  then     
	     write (Geom_Time1,89) 
     &		nodex(numIB,i),nodey(numIB,i),nodez(numIB,i) 
	   endif
   	 enddo
	do i=1,K
	  nodex(numIB,K+i)=nodexlocal(numIB,i)*(-0.5)-
     &      	            nodeylocal(numIB,i)*(SQRT(3.d0)/2.d0)
 	  nodey(numIB,K+i)=nodexlocal(numIB,i)*(SQRT(3.d0)/2.d0)+
     &     	             nodeylocal(numIB,i)*(-0.5)
	  nodex(numIB,K+i)=nodex(numIB,K+i) + Cxor(numIB)! - R(numIB)*SQRT(3.)/2
	  nodey(numIB,K+i)=nodey(numIB,K+i) + Cyor(numIB)! - R(numIB)*0.5
	    if (mod(itime,n_out).eq.0)  then     
                write (Geom_Time1,89)
     &		 nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i)  
	    endif
	 enddo
	do i=1,K
	  nodex(numIB,2*K+i)=nodexlocal(numIB,i)*(-0.5)-
     &         	            nodeylocal(numIB,i)*(-SQRT(3.d0)/2.d0)
 	  nodey(numIB,2*K+i)=nodexlocal(numIB,i)*(-SQRT(3.d0)/2.d0)+
     &                     nodeylocal(numIB,i)*(-0.5)
	  nodex(numIB,2*K+i)=nodex(numIB,2*K+i) + Cxor(numIB)! + R(numIB)*SQRT(3.)/2
	  nodey(numIB,2*K+i)=nodey(numIB,2*K+i) + Cyor(numIB)! - R(numIB)*0.5

	  if (mod(itime,n_out).eq.0)  then
             write (Geom_Time1,89)
     &	nodex(numIB,2*K+i),nodey(numIB,2*K+i),nodez(numIB,2*K+i)   
	  endif
	enddo

	  if (mod(itime,n_out).eq.0) close(Geom_Time1)

	ENDIF

!-----------------	4- bodies      --------------------------------
	IF (imbnumber(numIB).eq.4) then
         if (mod(itime,n_out).eq.0) then
           write(char_block,'(I8)') itime
           strlen=LEN(TRIM(ADJUSTL(char_block)))
           char_block=REPEAT('0',(6-strlen))//TRIM(ADJUSTL(char_block))
           gridfile1='Blade_Time_'//TRIM(ADJUSTL(char_block))//'.plt'
         open (unit=Geom_Time1, file=gridfile1)
		 write(Geom_Time1,*)'title = points'
		 write(Geom_Time1,*)'variables="x","y","z"'
		 write(Geom_Time1,*)
     &  	  'zone   ','i=  ',nodes(numIB),'DATAPACKING = POINT'
	 endif
       do i=1,K
	  nodex(numIB,i) = nodexlocal(numIB,i) + Cxor(numIB)
	  nodey(numIB,i) = nodeylocal(numIB,i) + Cyor(numIB)
	if (mod(itime,n_out).eq.0)  then        
	 write (Geom_Time1,89) 
     &		nodex(numIB,i),nodey(numIB,i),nodez(numIB,i) 
	endif
       enddo
        do i=1,K
          nodex(numIB,K+i)=-nodeylocal(numIB,i) + Cxor(numIB)
          nodey(numIB,K+i)=nodexlocal(numIB,i) + Cyor(numIB)
	 if (mod(itime,n_out).eq.0)  then     
               write (Geom_Time1,89)
     &		 nodex(numIB,K+i),nodey(numIB,K+i),nodez(numIB,K+i)
	 endif
       enddo
        do i=1,K
          nodex(numIB,2*K+i)=-nodexlocal(numIB,i) + Cxor(numIB)
          nodey(numIB,2*K+i)=-nodeylocal(numIB,i) + Cyor(numIB)
	 if (mod(itime,n_out).eq.0)  then    
             write (Geom_Time1,89)
     &	nodex(numIB,2*K+i),nodey(numIB,2*K+i),nodez(numIB,2*K+i) 
	 endif
       enddo
        do i=1,K
          nodex(numIB,3*K+i)=nodeylocal(numIB,i)  + Cxor(numIB)
          nodey(numIB,3*K+i)=-nodexlocal(numIB,i) + Cyor(numIB)
          if (mod(itime,n_out).eq.0)  then      
             write (Geom_Time1,89)
     &	nodex(numIB,3*K+i),nodey(numIB,3*K+i),nodez(numIB,3*K+i)
	  endif
       enddo

	  if (mod(itime,n_out).eq.0)  close(Geom_Time1)
	ENDIF
	
!-------------------------------------------------------------------	
	ENDIF
	IF (turax(numIB).eq.2) then	! Horizontal Axis Turbine

       do L=1,nodes(numIB)
        nodeylocal(numIB,L)=R0(numIB,L)*sin(rads(numIB)+alpha0(numIB,L))
        nodezlocal(numIB,L)=R0(numIB,L)*cos(rads(numIB)+alpha0(numIB,L))                    
       enddo   
!-----------------	1- body      --------------------------------
	IF (imbnumber(numIB).eq.1) then
         if (mod(itime,n_out).eq.0) then
           write(char_block,'(I8)') itime
           strlen=LEN(TRIM(ADJUSTL(char_block)))
           char_block=REPEAT('0',(6-strlen))//TRIM(ADJUSTL(char_block))
           gridfile1='HAT_Time_'//TRIM(ADJUSTL(char_block))//'.plt'
         open (unit=Geom_Time1, file=gridfile1)
	   write(Geom_Time1,*)'title = points'
	   write(Geom_Time1,*)'variables="x","y","z"'
	   write(Geom_Time1,*)
     &    'zone   ','i=  ',nodes(numIB),'DATAPACKING = POINT'
         endif
	  do i=1,nodes(numIB)
		nodey(numIB,i) = nodeylocal(numIB,i) + Cyor(numIB)
		nodez(numIB,i) = nodezlocal(numIB,i) + Czor(numIB)
   	    if (mod(itime,n_out).eq.0) then
	     write(Geom_Time1,89) 
     &		nodex(numIB,i),nodey(numIB,i),nodez(numIB,i)   
    	    endif
	  enddo

	  if (mod(itime,n_out).eq.0)  close(Geom_Time1)
	ENDIF       
          
       	
	ENDIF !AXIS


   88 FORMAT (i5)
   89 FORMAT (3f25.5)

        RETURN
        END SUBROUTINE	
