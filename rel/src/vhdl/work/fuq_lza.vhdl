-- © IBM Corp. 2020
-- This softcore is licensed under and subject to the terms of the CC-BY 4.0
-- license (https://creativecommons.org/licenses/by/4.0/legalcode). 
-- Additional rights, including the right to physically implement a softcore 
-- that is compliant with the required sections of the Power ISA 
-- Specification, will be available at no cost via the OpenPOWER Foundation. 
-- This README will be updated with additional information when OpenPOWER's 
-- license is available.


library ieee,ibm,support,tri,work;
   use ieee.std_logic_1164.all;
   use ibm.std_ulogic_unsigned.all;
   use ibm.std_ulogic_support.all; 
   use ibm.std_ulogic_function_support.all;
   use support.power_logic_pkg.all;
   use tri.tri_latches_pkg.all;
   use ibm.std_ulogic_ao_support.all; 
   use ibm.std_ulogic_mux_support.all; 



entity fuq_lza is
generic( expand_type: integer := 2  ); -- 0 - ibm tech, 1 - other );
port(

       vdd                                       :inout power_logic;
       gnd                                       :inout power_logic;
       clkoff_b                                  :in   std_ulogic; -- tiup
       act_dis                                   :in   std_ulogic; -- ??tidn??
       flush                                     :in   std_ulogic; -- ??tidn??
       delay_lclkr                               :in   std_ulogic_vector(3 to 4); -- tidn,
       mpw1_b                                    :in   std_ulogic_vector(3 to 4); -- tidn,
       mpw2_b                                    :in   std_ulogic_vector(0 to 0); -- tidn,
       sg_1                                      :in   std_ulogic;
       thold_1                                   :in   std_ulogic;
       fpu_enable                                :in   std_ulogic; --dc_act
       nclk                                      :in   clk_logic;

       f_lza_si                   :in  std_ulogic; --perv
       f_lza_so                   :out std_ulogic; --perv
       ex1_act_b                  :in  std_ulogic; --act

       f_sa3_ex3_s                :in  std_ulogic_vector( 0 to 162); -- data
       f_sa3_ex3_c                :in  std_ulogic_vector(53 to 161); -- data
       f_alg_ex2_effsub_eac_b     :in  std_ulogic;

       f_lze_ex2_lzo_din          :in  std_ulogic_vector(0 to 162);
       f_lze_ex3_sh_rgt_amt       :in  std_ulogic_vector(0 to 7);
       f_lze_ex3_sh_rgt_en        :in  std_ulogic ; 


       f_lza_ex4_no_lza_edge      :out std_ulogic;                   --fpic
       f_lza_ex4_lza_amt          :out std_ulogic_vector(0 to 7);    --fnrm
       f_lza_ex4_lza_dcd64_cp1    :out std_ulogic_vector(0 to 2);    --fnrm
       f_lza_ex4_lza_dcd64_cp2    :out std_ulogic_vector(0 to 1);    --fnrm
       f_lza_ex4_lza_dcd64_cp3    :out std_ulogic_vector(0 to 0);    --fnrm
       f_lza_ex4_sh_rgt_en        :out std_ulogic; 
       f_lza_ex4_sh_rgt_en_eov    :out std_ulogic; 
       f_lza_ex4_lza_amt_eov      :out std_ulogic_vector(0 to 7)     --feov
);


end fuq_lza; -- ENTITY

architecture fuq_lza of fuq_lza is

    constant tiup : std_ulogic := '1';
    constant tidn : std_ulogic := '0';

    signal thold_0_b, thold_0, forcee        :std_ulogic;
    signal sg_0                             :std_ulogic;
    signal ex2_act                          :std_ulogic;
    signal ex3_act                          :std_ulogic;
    signal ex1_act                          :std_ulogic;
    signal act_spare_unused                     :std_ulogic_vector(0 to   3);
    ----------------------------------------
    signal act_so                           :std_ulogic_vector(0 to   5);--SCAN
    signal act_si                           :std_ulogic_vector(0 to   5);--SCAN
    signal ex3_lzo_so                       :std_ulogic_vector(0 to 162);--SCAN
    signal ex3_lzo_si                       :std_ulogic_vector(0 to 162);--SCAN
    signal ex3_sub_so                       :std_ulogic_vector(0 to  0);--SCAN
    signal ex3_sub_si                       :std_ulogic_vector(0 to  0);--SCAN
    signal ex4_amt_so                       :std_ulogic_vector(0 to  15);--SCAN
    signal ex4_amt_si                       :std_ulogic_vector(0 to  15);--SCAN
    signal ex4_dcd_so                       :std_ulogic_vector(0 to  8);--SCAN
    signal ex4_dcd_si                       :std_ulogic_vector(0 to  8);--SCAN
    ----------------------------------------
    signal ex3_lza_any_b                    :std_ulogic;
    signal ex3_effsub                       :std_ulogic;
    signal ex4_no_edge       :std_ulogic;
    signal ex3_no_edge_b                      :std_ulogic;
    signal ex3_lzo                          :std_ulogic_vector(0 to 162);
    signal ex3_lza_amt_b                    :std_ulogic_vector(0 to 7);
    signal ex4_amt_eov                    :std_ulogic_vector(0 to 7);
    signal ex4_amt                        :std_ulogic_vector(0 to 7);
    signal ex3_sum                          :std_ulogic_vector(0 to 162);
    signal ex3_car                          :std_ulogic_vector(53 to 162);
    signal ex3_lv0_or   :std_ulogic_vector(0 to 162);   
    signal ex3_sh_rgt_en_b :std_ulogic;
    signal ex3_lv6_or_0_b , ex3_lv6_or_1_b , ex3_lv6_or_0_t , ex3_lv6_or_1_t  :std_ulogic;
    signal ex3_lza_dcd64_0_b , ex3_lza_dcd64_1_b , ex3_lza_dcd64_2_b  :std_ulogic;
    signal ex4_lza_dcd64_cp1 :std_ulogic_vector(0 to 2);
    signal ex4_lza_dcd64_cp2 :std_ulogic_vector(0 to 1);
    signal ex4_lza_dcd64_cp3 :std_ulogic_vector(0 to 0);
    signal ex4_sh_rgt_en :std_ulogic;
    signal ex4_sh_rgt_en_eov :std_ulogic;
    signal ex2_effsub_eac, ex2_effsub_eac_b  :std_ulogic;
    signal ex3_lzo_b, ex3_lzo_l2_b :std_ulogic_vector(0 to 162);
    signal ex3_lv6_or_0, ex3_lv6_or_1 :std_ulogic;
    signal ex3_rgt_amt_b :std_ulogic_vector(0 to 7);
    signal lza_ex4_d1clk , lza_ex4_d2clk :std_ulogic ;
    signal lza_ex3_d1clk , lza_ex3_d2clk :std_ulogic ;
    signal lza_ex4_lclk :clk_logic ;
    signal lza_ex3_lclk :clk_logic ;


--=###############################################################
--= map block attributes
--=###############################################################

begin

--=###############################################################
--= pervasive
--=###############################################################

    
    thold_reg_0:  tri_plat  generic map (expand_type => expand_type) port map (
         vd        => vdd,
         gd        => gnd,
         nclk      => nclk,  
         flush     => flush ,
         din(0)    => thold_1,   
         q(0)      => thold_0  ); 
    
    sg_reg_0:  tri_plat     generic map (expand_type => expand_type) port map (
         vd        => vdd,
         gd        => gnd,
         nclk      => nclk,
         flush     => flush ,
         din(0)    => sg_1  ,     
         q(0)      => sg_0  );   


    lcbor_0: tri_lcbor generic map (expand_type => expand_type ) port map (
        clkoff_b     => clkoff_b,
        thold        => thold_0,  
        sg           => sg_0,
        act_dis      => act_dis,
        forcee => forcee,
        thold_b      => thold_0_b );



--=###############################################################
--= act
--=###############################################################

        ex1_act <= not ex1_act_b;

    act_lat:  tri_rlmreg_p generic map (width=> 6, expand_type => expand_type, needs_sreset => 0) port map ( 
        forcee => forcee,--i-- tidn,
        delay_lclkr      => delay_lclkr(3)   ,--i-- tidn,
        mpw1_b           => mpw1_b(3)        ,--i-- tidn,
        mpw2_b           => mpw2_b(0)        ,--i-- tidn,
        vd               => vdd,
        gd               => gnd,
        nclk             => nclk,
        act              => fpu_enable,
        thold_b          => thold_0_b,
        sg               => sg_0, 
        scout            => act_so  ,                      
        scin             => act_si  ,                    
        -------------------
         din(0)             => act_spare_unused(0),
         din(1)             => act_spare_unused(1),
         din(2)             => ex1_act,
         din(3)             => ex2_act,
         din(4)             => act_spare_unused(2),
         din(5)             => act_spare_unused(3),
        -------------------
        dout(0)             => act_spare_unused(0),
        dout(1)             => act_spare_unused(1),
        dout(2)             => ex2_act,
        dout(3)             => ex3_act,
        dout(4)             => act_spare_unused(2) ,
        dout(5)             => act_spare_unused(3) );


    lza_ex3_lcb : tri_lcbnd generic map (expand_type => expand_type) port map(
        delay_lclkr =>  delay_lclkr(3) ,-- tidn ,--in
        mpw1_b      =>  mpw1_b(3)      ,-- tidn ,--in
        mpw2_b      =>  mpw2_b(0)      ,-- tidn ,--in
        forcee => forcee,-- tidn ,--in
        nclk        =>  nclk                 ,--in
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        act         =>  ex2_act              ,--in
        sg          =>  sg_0                 ,--in
        thold_b     =>  thold_0_b            ,--in
        d1clk       =>  lza_ex3_d1clk        ,--out
        d2clk       =>  lza_ex3_d2clk        ,--out
        lclk        =>  lza_ex3_lclk        );--out

    lza_ex4_lcb : tri_lcbnd generic map (expand_type => expand_type) port map(
        delay_lclkr =>  delay_lclkr(4) ,-- tidn ,--in
        mpw1_b      =>  mpw1_b(4)      ,-- tidn ,--in
        mpw2_b      =>  mpw2_b(0)      ,-- tidn ,--in
        forcee => forcee,-- tidn ,--in
        nclk        =>  nclk                 ,--in
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        act         =>  ex3_act              ,--in
        sg          =>  sg_0                 ,--in
        thold_b     =>  thold_0_b            ,--in
        d1clk       =>  lza_ex4_d1clk        ,--out
        d2clk       =>  lza_ex4_d2clk        ,--out
        lclk        =>  lza_ex4_lclk        );--out


--=###############################################################
--= ex3 latches
--=###############################################################

    ex3_lzo_lat:   entity tri.tri_inv_nlats(tri_inv_nlats) generic map (width=> 163, btr => "NLI0001_X1_A12TH",  expand_type => expand_type,  needs_sreset => 0  ) port map ( 
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        LCLK             => lza_ex3_lclk               ,-- lclk.clk
        D1CLK            => lza_ex3_d1clk              ,
        D2CLK            => lza_ex3_d2clk              ,
        SCANIN           => ex3_lzo_si                 ,                    
        SCANOUT          => ex3_lzo_so                 ,                      
        D                => f_lze_ex2_lzo_din(0 to 162),
        QB               => ex3_lzo_l2_b(0 to 162)    );


 zobx: ex3_lzo  (0 to 162) <= not ex3_lzo_l2_b(0 to 162);
 zob:  ex3_lzo_b(0 to 162) <= not ex3_lzo     (0 to 162);

    ex2_effsub_eac <= not f_alg_ex2_effsub_eac_b  ;
    ex2_effsub_eac_b <= not ex2_effsub_eac ;

    ex3_sub_lat:   entity tri.tri_inv_nlats(tri_inv_nlats) generic map (width=> 1, btr => "NLI0001_X2_A12TH",  expand_type => expand_type,  needs_sreset => 0  ) port map ( 
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        LCLK             => lza_ex3_lclk               ,-- lclk.clk
        D1CLK            => lza_ex3_d1clk              ,
        D2CLK            => lza_ex3_d2clk              ,
        SCANIN(0)        => ex3_sub_si(0)              ,                    
        SCANOUT(0)       => ex3_sub_so(0)              ,                      
        D(0)             => ex2_effsub_eac_b           ,
        QB(0)            => ex3_effsub                );


     ex3_sum(0 to 52) <= f_sa3_ex3_s(0 to 52) ;

--=###############################################################
--= ex3 logic
--=###############################################################

    ex3_sum(53 to 162) <= f_sa3_ex3_s(53 to 162);
    ex3_car(53 to 162) <= f_sa3_ex3_c(53 to 161)  & tidn;

    --=#------------------------------------------------
    --=#-- EDGE DETECTION
    --=#------------------------------------------------

      lzaej:  entity work.fuq_lza_ej(fuq_lza_ej) port map(
          effsub            => ex3_effsub             ,--i--
          sum(0 to 162)     => ex3_sum(0 to 162)      ,--i--
          car(53 to 162)    => ex3_car(53 to 162)     ,--i--
          lzo_b(0 to 162)   => ex3_lzo_b(0 to 162)    ,--i--
          edge(0 to 162)    => ex3_lv0_or(0 to 162)  );--o--

    --=#------------------------------------------------
    --=#-- ENCODING TREE (CLZ) count leading zeroes
    --=#------------------------------------------------

      lzaclz:  entity work.fuq_lza_clz(fuq_lza_clz) port map(
          lv0_or(0 to 162)   => ex3_lv0_or(0 to 162)     ,--i--
          lv6_or_0           => ex3_lv6_or_0             ,--o--
          lv6_or_1           => ex3_lv6_or_1             ,--o--
          lza_any_b          => ex3_lza_any_b            ,--i--
          lza_amt_b(0 to 7)  => ex3_lza_amt_b(0 to 7)   );--o--


      ex3_no_edge_b <= not ex3_lza_any_b ;

--=###############################################################
--= ex4 latches
--=###############################################################

      ex3_rgt_amt_b(0 to 7) <= not f_lze_ex3_sh_rgt_amt(0 to 7);



         ex3_sh_rgt_en_b <= not f_lze_ex3_sh_rgt_en ;


lzdz0b:  ex3_lv6_or_0_b <= not ex3_lv6_or_0 ;
lzdz1b:  ex3_lv6_or_1_b <= not ex3_lv6_or_1 ;
lzdz0t:  ex3_lv6_or_0_t <= not ex3_lv6_or_0_b ;
lzdz1t:  ex3_lv6_or_1_t <= not ex3_lv6_or_1_b ;

lzd0b:   ex3_lza_dcd64_0_b <= not(ex3_lv6_or_0_t and                    ex3_sh_rgt_en_b); 
lzd1b:   ex3_lza_dcd64_1_b <= not(ex3_lv6_or_0_b and ex3_lv6_or_1_t and ex3_sh_rgt_en_b);
lzd2b:   ex3_lza_dcd64_2_b <= not(ex3_lv6_or_0_b and ex3_lv6_or_1_b and ex3_sh_rgt_en_b);






    ex4_dcd_lat:   entity tri.tri_inv_nlats(tri_inv_nlats) generic map (width=> 9, btr => "NLI0001_X2_A12TH" , expand_type => expand_type,  needs_sreset => 0  ) port map ( 
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        LCLK             => lza_ex4_lclk               ,-- lclk.clk
        D1CLK            => lza_ex4_d1clk              ,
        D2CLK            => lza_ex4_d2clk              ,
        SCANIN           => ex4_dcd_si(0 to 8)         ,                    
        SCANOUT          => ex4_dcd_so(0 to 8)         ,                      
        D( 0)          => ex3_lza_dcd64_0_b   ,--( 0)
        D( 1)          => ex3_lza_dcd64_0_b   ,--( 1)
        D( 2)          => ex3_lza_dcd64_0_b   ,--( 2)
        D( 3)          => ex3_lza_dcd64_1_b   ,--( 3)
        D( 4)          => ex3_lza_dcd64_1_b   ,--( 4)
        D( 5)          => ex3_lza_dcd64_2_b ,--( 5)
        D( 6)          => ex3_sh_rgt_en_b   ,--( 6)
        D( 7)          => ex3_sh_rgt_en_b   ,--( 7)
        D( 8)          => ex3_no_edge_b     ,--(24)
        -------------------
        QB( 0)         => ex4_lza_dcd64_cp1(0), --( 6)
        QB( 1)         => ex4_lza_dcd64_cp2(0), --( 9)
        QB( 2)         => ex4_lza_dcd64_cp3(0), --( 1)
        QB( 3)         => ex4_lza_dcd64_cp1(1), --( 7)
        QB( 4)         => ex4_lza_dcd64_cp2(1), --( 0)
        QB( 5)         => ex4_lza_dcd64_cp1(2), --( 8)
        QB( 6)         => ex4_sh_rgt_en       , --( 2)
        QB( 7)         => ex4_sh_rgt_en_eov   , --( 3)
        QB( 8)         => ex4_no_edge        ); --(24)


    ex4_amt_lat:   entity tri.tri_nand2_nlats(tri_nand2_nlats) generic map (width=> 16, btr => "NLA0001_X1_A12TH", expand_type => expand_type,  needs_sreset => 0  ) port map ( 
        vd          =>  vdd                  ,--inout
        gd          =>  gnd                  ,--inout
        LCLK             => lza_ex4_lclk        ,--in   --lclk.clk
        D1CLK            => lza_ex4_d1clk       ,--in
        D2CLK            => lza_ex4_d2clk       ,--in
        SCANIN           => ex4_amt_si(0 to 15) ,                    
        SCANOUT          => ex4_amt_so(0 to 15) ,                      
        A1( 0)          => ex3_lza_amt_b(0)     ,--( 8)
        A1( 1)          => ex3_lza_amt_b(0)     ,--( 9)
        A1( 2)          => ex3_lza_amt_b(1)     ,--(10)
        A1( 3)          => ex3_lza_amt_b(1)     ,--(11)
        A1( 4)          => ex3_lza_amt_b(2)     ,--(12)
        A1( 5)          => ex3_lza_amt_b(2)     ,--(13)
        A1( 6)          => ex3_lza_amt_b(3)     ,--(14)
        A1( 7)          => ex3_lza_amt_b(3)     ,--(15)
        A1( 8)          => ex3_lza_amt_b(4)     ,--(16)
        A1( 9)          => ex3_lza_amt_b(4)     ,--(17)
        A1(10)          => ex3_lza_amt_b(5)     ,--(18)
        A1(11)          => ex3_lza_amt_b(5)     ,--(19)
        A1(12)          => ex3_lza_amt_b(6)     ,--(20)
        A1(13)          => ex3_lza_amt_b(6)     ,--(21)
        A1(14)          => ex3_lza_amt_b(7)     ,--(22)
        A1(15)          => ex3_lza_amt_b(7)     ,--(23)

        A2( 0)          => ex3_rgt_amt_b(0)     ,--( 8)
        A2( 1)          => ex3_rgt_amt_b(0)     ,--( 9)
        A2( 2)          => ex3_rgt_amt_b(1)     ,--(10)
        A2( 3)          => ex3_rgt_amt_b(1)     ,--(11)
        A2( 4)          => ex3_rgt_amt_b(2)     ,--(12)
        A2( 5)          => ex3_rgt_amt_b(2)     ,--(13)
        A2( 6)          => ex3_rgt_amt_b(3)     ,--(14)
        A2( 7)          => ex3_rgt_amt_b(3)     ,--(15)
        A2( 8)          => ex3_rgt_amt_b(4)     ,--(16)
        A2( 9)          => ex3_rgt_amt_b(4)     ,--(17)
        A2(10)          => ex3_rgt_amt_b(5)     ,--(18)
        A2(11)          => ex3_rgt_amt_b(5)     ,--(19)
        A2(12)          => ex3_rgt_amt_b(6)     ,--(20)
        A2(13)          => ex3_rgt_amt_b(6)     ,--(21)
        A2(14)          => ex3_rgt_amt_b(7)     ,--(22)
        A2(15)          => ex3_rgt_amt_b(7)     ,--(23)

        -------------------
        QB( 0)         => ex4_amt(0)          , --( 0)
        QB( 1)         => ex4_amt_eov(0)      , --( 8)
        QB( 2)         => ex4_amt(1)          , --(11)
        QB( 3)         => ex4_amt_eov(1)      , --(19)
        QB( 4)         => ex4_amt(2)          , --(12)
        QB( 5)         => ex4_amt_eov(2)      , --(10)
        QB( 6)         => ex4_amt(3)          , --(13)
        QB( 7)         => ex4_amt_eov(3)      , --(11)
        QB( 8)         => ex4_amt(4)          , --(14)
        QB( 9)         => ex4_amt_eov(4)      , --(12)
        QB(10)         => ex4_amt(5)          , --(15)
        QB(11)         => ex4_amt_eov(5)      , --(13)
        QB(12)         => ex4_amt(6)          , --(26)
        QB(13)         => ex4_amt_eov(6)      , --(24)
        QB(14)         => ex4_amt(7)          , --(27)
        QB(15)         => ex4_amt_eov(7)     ); --(24)




       f_lza_ex4_sh_rgt_en     <= ex4_sh_rgt_en ;
       f_lza_ex4_sh_rgt_en_eov <= ex4_sh_rgt_en_eov ;

       f_lza_ex4_lza_amt      <=  ex4_amt(0 to 7)      ;--output-- --fnrm--

       f_lza_ex4_lza_dcd64_cp1(0 to 2)  <= ex4_lza_dcd64_cp1(0 to 2); --ouptut-- --fnrm
       f_lza_ex4_lza_dcd64_cp2(0 to 1)  <= ex4_lza_dcd64_cp2(0 to 1); --ouptut-- --fnrm
       f_lza_ex4_lza_dcd64_cp3(0)       <= ex4_lza_dcd64_cp3(0)     ; --ouptut-- --fnrm


       f_lza_ex4_lza_amt_eov  <=     ex4_amt_eov(0 to 7)  ;--output-- --feov--
       f_lza_ex4_no_lza_edge  <=     ex4_no_edge          ;--output-- --fpic--

--=###############################################################
--= scan string
--=###############################################################

  ex3_lzo_si  (0 to 162) <= ex3_lzo_so  (1 to 162) & f_lza_si ;
  ex3_sub_si  (0)        <=                          ex3_lzo_so  (0);
  ex4_amt_si  (0 to  15) <= ex4_amt_so  (1 to  15) & ex3_sub_so  (0);
  ex4_dcd_si  (0 to   8) <= ex4_dcd_so  (1 to   8) & ex4_amt_so  (0);
  act_si      (0 to   5) <= act_so      (1 to   5) & ex4_dcd_so  (0);
  f_lza_so               <= act_so  (0);



end; -- fuq_lza ARCHITECTURE
