 100 ' S.P.O.T. — Satellite Position and Orbital Tracking
 105 ' ISS tracking program in SuperBASIC
 110 ' 2026 Michael Cassera

 115 ' This program uses the wizfi module to connect to the internet
 120 ' and retrieve the current position of the International Space 
 125 ' Station (ISS) from an online API.
 130 '
 135 ' wizfi registers
 140 wiz_ctrl = $dd80
 145 wiz_data = $dd81
 150 wiz_fifo = $dd82

 155 ' wizfi status byte
 160 ' software driven
 165 wizfi_status = $b0
 170 ip_status = $b1

 175 ' network led registers
 180 k2_leds = $d6a0
 185 ntwk_rgb = $d6b3

 190 ' Set up some colors for the display
 195 ltb$=chr$(128+7)
 200 bl$=chr$(128+10)
 205 rd$=chr$(128+13)

 210 ' Set up the display
 215 sprites on
 220 bitmap on
 225 bitmap clear 0

 230 ' Initialize the WIZFi module
 235 poke wiz_ctrl, 0

 240 ' setup screens and sprites
 245 makesprite()
 250 drawmap()


 255 ' set up the WIZFi module with the necessary commands
 260 initialize()
 265 connect()
 270 connect_api()

 275 cursor off

 280 ' Get ISS position from API
 285 link$="AT+CIPSEND=57"
 290 s$="GET /iss-now.json HTTP/1.1"+chr$(13)+chr$(10)
 295 s$=s$+"Host: api.open-notify.org"+chr$(13)+chr$(10)+chr$(13)+chr$(10)

 300 pl_counter=0:recon=0

 305 repeat
 310     sendcommand(link$)
 315     delay(10000)
 320     silentread()
 325     sendcommand(s$)
 330     delay(10000)
 335     getdata()
 340     if (lat$<>"")&(lon$<>"")
 345         lat#=val(lat$)
 350         lon#=val(lon$)
 355         ts=val(tms$)
 360         hh=ts\3600
 365         hh=hh%24
 370         mm=ts\60
 375         mm=mm%60
 380         ss=ts%60
 385     else
 390         recon=recon+1
 395         if recon>1
 400             print at 20,28; rd$;"RECONNECTION ATTEMPT"
 405             connect_api()
 410             recon=0
 415         endif
 420     endif
 425     cls
    
 430     print ltb$
 435     print "                S.P.O.T. — ";ltb$;"S";bl$;"atellite ";ltb$;
 440     print "P";bl$;"osition and ";ltb$;"O";bl$;"rbital ";ltb$;"T";
 445     print bl$;"racking"
 450     print at 57,20; "UTC Time: ";ltb$;hh;":";
 455     if mm<10 then print "0";
 460     print mm;":";
 465     if ss<10 then print "0";
 470     print ss
 475     print at 56,45; bl$;"Latitude  ";ltb$;lat#
 480     print at 57,45; bl$;"Longitude ";ltb$;lon#
 485     x=int((lon#+180)/360*319+0.5)
 490     y=int((90-lat#)/180*239+0.5)
 495     pl_counter=pl_counter+1
 500     if pl_counter>5
 505         pl_counter=0
 510         line color 10 x,y to x,y
 515     endif
 520     sprite 0 image 0 to x,y
 525     q$=inkey$()
 530     if (q$<>"") & (q$<>"q")
 535         print at 20,28; rd$"PRESS Q TO EXIT PROGRAM";
 540     endif
 545     if q$="q"
 550         print at 21,28; rd$"EXITING PROGRAM";
 555     else
 560         delay(100000) 
 565     endif
 570 until q$="q"

 575 ' Clean up and exit
 580 cursor on
 585 bitmap off
 590 sprites off
 595 cls
 600 print rd$;"PROGRAM TERMINATED"
 605 end

 610 ' --- PROCEDURES ---
 615 proc initialize()
 620     ' Send initialization commands to the WIZFi module
 625     repeat
 630         read a$
 635         if a$<>"stop" 
 640             sendcommand(a$)
 645             delay(10000)
 650             readresponse()
 655         endif
 660     until a$="stop"
 665 endproc

 670 proc connect()
 675     ' Connect to WiFi
 680     poke ip_status, 0
 685     print "CONNECTING TO WIFI..."
 690     print "IF ALREADY CONNECTED, PRESS ENTER."
 695     print
 700     print "Enter WIFI ID: ";
 705     input wifi_id$
 710     if wifi_id$<>""
 715         print "Enter WIFI password: ";
 720         input wifi_pass$
 725         repeat
 730             cmd$ = "AT+CWJAP_CUR='"+wifi_id$+"','"+wifi_pass$+"'"
 735             sendcommand(cmd$)
 740             delay(50000)
 745             readresponse()
 750         until peek(ip_status)=1
 755     endif
 760     sendcommand("AT+CIPSTA_CUR?")
 765     delay(50000)
 770     readresponse()
 775 endproc

 780 proc connect_api()
 785     ' Connect to the API server for iss position data
 790     sendcommand("AT+CIPSTART='TCP','api.open-notify.org',80")
 795     delay(50000)
 800     readresponse()
 805 endproc

 810 proc sendcommand(cmd$)
 815     ' Send a command to the WIZFi module
 820     poke k2_leds, peek(k2_leds)|64
 825     for n=1 to len(cmd$)
 830         pokel ntwk_rgb, $0000ff
 835         b=asc(mid$(cmd$,n,1))
 840         if b=39 then b=34 
 845         pokel ntwk_rgb, $000000
 850         poke wiz_data, b
 855     next
 860     poke wiz_data, 13 
 865     poke wiz_data, 10
 870     poke k2_leds, peek(k2_leds) & $bf
 875 endproc

 880 proc readresponse()
 885     ' Read the response from the WIZFi module and 
 890     ' print it to the screen
 895     r$="0123456789"
 900     poke k2_leds, peek(k2_leds)|64
 905     while peek(wiz_fifo)<>0
 910         pokel ntwk_rgb, $ff0000
 915         b=peek(wiz_data)
 920         pokel ntwk_rgb, $000000
 925         print chr$(b);
 930         r$=right$(r$+chr$(b),10)
 935         if right$(r$,2)="OK" then poke wizfi_status, 1
 940         if right$(r$,4)="FAIL" then poke wizfi_status, 9
 945         if right$(r$,5)="ERROR" then poke wizfi_status, 8
 950         if right$(r$,9)="busy p..." then poke wizfi_status, 2
 955         if right$(r$,6)="GOT IP" then poke ip_status, 1
 960     wend
 965     poke k2_leds, peek(k2_leds) & $bf
 970 endproc

 975 proc silentread()
 980     ' Read the response from the WIZFi module 
 985     ' without printing it to the screen
 990     r$="0123456789"
 995     poke k2_leds, peek(k2_leds)|64
1000     while peek(wiz_fifo)<>0
1005         pokel ntwk_rgb, $ff0000
1010         b=peek(wiz_data)
1015         pokel ntwk_rgb, $000000
1020         r$=right$(r$+chr$(b),10)
1025         if right$(r$,2)="OK" then poke wizfi_status, 1
1030         if right$(r$,4)="FAIL" then poke wizfi_status, 9
1035         if right$(r$,5)="ERROR" then poke wizfi_status, 8
1040         if right$(r$,9)="busy p..." then poke wizfi_status, 2
1045         if right$(r$,6)="GOT IP" then poke ip_status, 1
1050     wend
1055     poke k2_leds, peek(k2_leds) & $bf
1060 endproc

1065 proc getdata()
1070     ' Read the data from the API response and
1075     ' extract the latitude and longitude
1080     poke k2_leds, peek(k2_leds)|64
1085     bf$="12345678901234567":state=0:lgth$=""
1090     lt$=chr$(34)+"latitude"+chr$(34)+": "+chr$(34)
1095     ln$=chr$(34)+"longitude"+chr$(34)+": "+chr$(34) 
1100     ts$=chr$(34)+"timestamp"+chr$(34)+": "
1105     lat$="":lon$="":clen$="":tms$=""
1110     ct$="Content-Length: ":ct=0
1115     do_count=0
1120     rnlf$=chr$(13)+chr$(10)+chr$(13)+chr$(10)
1125     repeat
1130         while peek(wiz_fifo)>0
1135             pokel ntwk_rgb, $ff0000
1140             b=peek(wiz_data)
1145             if state=1
1150                 if chr$(b)=":"
1155                     state=2
1160                     lgth=val(lgth$)
1165                     latlon=0
1170                 else
1175                     lgth$=lgth$+chr$(b)
1180                 endif
1185             endif
1190             if state=0
1195                 bf$=right$(bf$+chr$(b),20)
1200                 if right$(bf$,5)="+IPD," then state=1
1205             endif
1210             if state=2
1215                 for n=1 to lgth
1220                     if do_count=1 then ct=ct-1
1225                     b=peek(wiz_data)
1230                     pokel ntwk_rgb, $ff0000
1235                     bf$=bf$+chr$(b)
1240                     bf$=right$(bf$,16)
1245                     if latlon = 0
1250                          if right$(bf$,13)=lt$ then latlon=1
1255                          if right$(bf$,14)=ln$ then latlon=2
1260                          if right$(bf$,13)=ts$ then latlon=3
1265                          if right$(bf$,15)=ct$ then latlon=4
1270                     else
1275                         if latlon=1
1280                             if b=34
1285                                 latlon=0
1290                             else 
1295                                 lat$=lat$+chr$(b)
1300                             endif
1305                         endif
1310                         if latlon=2
1315                             if b=34
1320                                 latlon=0
1325                             else 
1330                                 lon$=lon$+chr$(b)
1335                             endif
1340                         endif
1345                         if latlon=3
1350                             if (b<48)|(b>57)
1355                                 latlon=0
1360                             else 
1365                                 tms$=tms$+chr$(b)
1370                             endif
1375                         endif
1380                         if latlon=4
1385                             if b=13
1390                                 latlon=5
1395                                 ct=val(clen$)
1400                             else 
1405                                 clen$=clen$+chr$(b)
1410                             endif
1415                         endif
1420                         if latlon=5
1425                             if right$(bf$,4)=rnlf$
1430                                 do_count=1
1435                                 latlon=0
1440                             endif
1445                         endif
1450                     endif
1455                     pokel ntwk_rgb, $000000
1460                 next
1465                 state=4
1470             endif
1475             pokel ntwk_rgb, $000000
1480         wend
1485     until ct<1
1490     poke k2_leds, peek(k2_leds) & $bf
1495 endproc

1500 proc makesprite()
1505     ' Create a sprite for the ISS icon
1510     for n=0 to 259
1515         read b
1520         poke $7800+n, b
1525     next
1530     memcopy $7800, 260 to $30000
1535 endproc

1540 proc drawmap()
1545     ' Draw the world map using the coastline data
1550     cls
1555     while ln<>888
1560         read ln,lt
1565         if ln <> 888
1570             if ln=999
1575                 read ln,lt
1580                 x=int((ln+180)/360*319+0.5)
1585                 y=int((90-lt)/180*239+0.5)
1590                 plot x,y 
1595             else
1600                 x=int((ln+180)/360*319+0.5)
1605                 y=int((90-lt)/180*239+0.5)
1610                 line color 40 to x,y
1615             endif
1620         endif
1625     wend
1630 endproc

1635 proc delay(count)
1640     ' Simple delay loop to waste time
1645     for i=1 to count
1650         ' do nothing, just waste time
1655     next
1660 endproc


1665 ' sprite data for the ISS icon
1670 data $11,$1,$0
1675 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1680 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1685 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1690 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1695 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1700 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1705 data $0,$8,$0,$8,$0,$0,$0,$b,$0,$0,$0,$8,$0,$8,$0,$0
1710 data $0,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$0,$0
1715 data $0,$8,$0,$8,$0,$0,$0,$b,$0,$0,$0,$8,$0,$8,$0,$0
1720 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1725 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1730 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1735 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1740 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1745 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1750 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1755 data $80

1760 ' GLOBAL COASTLINE DATA 
1765 ' =========================================

1770 ' --- NORTH AMERICA ------------------------
1775 data 999,999
1780 data -124,48,-123,39,-117,32,-110,24,-109,23,-110,24
1785 data -114,30,-114,31,-105,21,-105,20,-97,15,-94,16
1790 data -91,14,-88,13,-84,9,-80,7,-79,8,-77,7,-77,8
1795 data -80,8,-82,10,-84,12,-83,15,-88,16,-87,21,-89,22
1800 data -91,21,-91,19,-95,18,-98,22,-97,26,-97,28,-94,30
1805 data -90,29,-88,30,-84,30,-82,26,-80,25,-80,28,-82,31
1810 data -80,33,-76,35,-75,38,-72,41,-68,45,-63,45,-65,47
1815 data -63,50,-54,47,-53,49,-65,61,-67,59,-75,63,-78,62
1820 data -79,52,-80,52,-83,55,-94,59,-85,67,-114,69,-143,70
1825 data -158,71,-167,68,-165,60,-158,59,-159,57,-169,53
1830 data -159,56,-151,60,-139,59,-131,53,-124,48

1835 data 999,999
1840 data -78,64,-74,64,-70,62,-65,62,-62,67,-77,74,-86,74
1845 data -90,72,-86,68,-85,66,-87,64,-85,63,-82,64,-83,66
1850 data -80,70,-72,68,-75,66,-77,65,-78,64

1855 data 999,999
1860 data -61,83,-81,75,-90,75,-114,75,-123,76,-98,80,-77,83,-61,83

1865 data 999,999
1870 data -124,74,-125,72,-122,71,-119,72,-117,69,-109,69
1875 data -106,69,-102,68,-92,70,-97,74,-103,73,-105,74
1880 data -111,73,-118,74,-124,74

1885 ' --- SOUTH AMERICA ------------------------
1890 data 999,999
1895 data -78,7,-77,4,-78,0,-81,-5,-76,-15,-70,-19,-72,-31
1900 data -71,-33,-74,-40,-76,-49,-74,-53,-71,-55,-67,-55
1905 data -64,-54,-68,-53,-68,-50,-62,-40,-52,-32,-47,-25
1910 data -42,-23,-39,-17,-39,-13,-34,-8,-35,-5,-46,-1
1915 data -50,2,-52,6,-57,6,-62,11,-69,12,-75,11,-78,7

1920 ' --- EUROPE -------------------------------
1925 data 999,999
1930 data 31,70,26,71,14,68,10,64,5,62,6,59,7,58,11,59,13,57
1935 data 9,57,7,53,1,49,-5,48,-1,46,-2,43,-9,44,-9,37
1940 data -2,37,4,43,10,44,13,41,16,39,16,39,18,40,13,44
1945 data 13,46,19,42,20,39,23,38,24,40,28,42,31,46,38,47

1950 data 999,999
1955 data 0,54,-2,56,-3,59,-6,58,-3,54,-5,50,0,51,2,53,0,54

1960 data 999,999
1965 data -10,54,-10,52,-7,52,-6,54,-8,55,-10,54

1970 data 999,999
1975 data 25,66,21,65,17,61,18,59,16,56,12,55,14,54,21,56
1980 data 23,59,28,60,28,61,21,60,19,60,25,66

1985 ' --- AFRICA -------------------------------
1990 data 999,999
1995 data -13,28,-17,21,-17,12,-8,4,3,6,9,3,14,-10
2000 data 12,-19,19,-34,27,-34,35,-23,36,-18,41,-15
2005 data 39,-7,43,0,49,7,52,12,45,10,38,17,34,27
2010 data 32,31,21,33,19,30,10,34,10,37,0,37,-9,33
2015 data -13,28

2020 ' --- ASIA --------------------------------
2025 data 999,999
2030 data 38,47,38,45,42,42,40,41,33,42,27,40,28,37
2035 data 33,36,37,37,34,31,33,31,34,28,35,27,43,17
2040 data 44,12,52,16,60,22,56,25,56,26,54,24,51,25
2045 data 48,29,49,30,52,28,55,26,57,27,58,25,67,25
2050 data 70,21,73,20,75,14,77,8,80,12,80,16,87,20
2055 data 88,22,92,23,95,16,97,17,99,12,105,9,109,12
2060 data 109,15,105,19,108,22,115,23,120,26,122,30
2065 data 118,39,121,40,126,38,126,34,129,36,129,38
2070 data 127,40,135,44,140,49,141,54,136,55,145,59
2075 data 154,60,164,62,159,58,155,56,157,51,178,64
2080 data 170,66,174,70,132,70,102,77,68,69,43,66,31,70

2085 ' --- AUSTRALIA ----------------------------
2090 data 999,999
2095 data 121,-20,115,-21,113,-24,115,-31,115,-35
2100 data 119,-35,127,-32,134,-32,142,-38,149,-38
2105 data 153,-31,151,-23,146,-19,143,-12,142,-11
2110 data 141,-18,135,-15,137,-12,131,-12,129,-15
2115 data 125,-14,123,-17,121,-20

2120 ' --- GREENLAND ----------------------------
2125 data 999,999
2130 data -37,65,-31,68,-26,69,-21,70,-18,75,-19,79
2135 data -11,82,-33,84,-60,82,-72,78,-68,76,-60,76
2140 data -53,66,-49,61,-44,60,-41,63,-40,65,-37,65

2145 ' --- ANTARCTICA ---------------------------
2150 data 999,999
2155 data 179,-78,165,-76,168,-74,171,-72,165,-70
2160 data 138,-66,113,-66,83,-66,76,-69,58,-66
2165 data 46,-67,12,-70,-10,-70,-25,-74,-42,-78
2170 data -59,-75,-61,-66,-56,-63,-65,-66,-76,-73
2175 data -101,-72,-103,-75,-126,-73,-148,-75
2180 data -162,-78,-179,-78

2185 ' --- SMALL ISLANDS -------------------------
2190 data 999,999
2195 data 142,45,139,39,134,36,129,33,130,30,135,34
2200 data 141,36,142,45

2205 data 999,999
2210 data 151,-10,145,-4,138,-1,132,-3,141,-9,151,-10

2215 data 999,999
2220 data 98,13,99,8,102,2,98,4,95,5,105,-7,120,-9
2225 data 126,-8,112,-7,106,-5,103,1,105,1,103,6
2230 data 100,8,96,14,98,13

2235 data 999,999
2240 data 109,1,111,-3,116,-4,118,2,118,6,117,8,114,4,109,1

2245 data 999,999
2250 data -18,63,-13,65,-16,67,-20,66,-23,66,-24,65,-18,63

2255 data 888,888

2260 ' control commands to initialize the module
2265 data "AT+GMR"
2270 data "AT+UART_CUR?"
2275 data "AT+CWMODE_CUR=1"
2280 data "AT+CWMODE_CUR?"
2285 data "AT+CIPMUX=0"
2290 data "stop"

2295 ' =========================================
2300 ' END DATA