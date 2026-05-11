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

 155 ' network led registers
 160 k2_leds = $d6a0
 165 ntwk_rgb = $d6b3

 170 ' Set up some colors for the display
 175 ltb$=chr$(128+7)
 180 bl$=chr$(128+10)
 185 rd$=chr$(128+13)

 190 ' Set up the display
 195 sprites on
 200 bitmap on
 205 bitmap clear 0

 210 ' Initialize the WIZFi module
 215 poke wiz_ctrl, 0

 220 ' set up the WIZFi module with the necessary commands
 225 print"PRESS Q to EXIT PROGRAM AFTER MAP LOADS"
 230 initialize()
 235 connect()
 240 connect_api()
 245 makesprite()
 250 drawmap()
 255 cursor off

 260 ' Get ISS position from API
 265 link$="AT+CIPSEND=57"
 270 s$="GET /iss-now.json HTTP/1.1"+chr$(13)+chr$(10)
 275 s$=s$+"Host: api.open-notify.org"+chr$(13)+chr$(10)+chr$(13)+chr$(10)

 280 pl_counter=0:recon=0

 285 repeat
 290     sendcommand(link$)
 295     delay(10000)
 300     silentread()
 305     sendcommand(s$)
 310     delay(10000)
 315     getdata()
 320     if (lat$<>"")&(lon$<>"")
 325         lat#=val(lat$)
 330         lon#=val(lon$)
 335     else
 340         recon=recon+1
 345         if recon>1
 350             print rd$"                   RECONNECTION ATTEMPT";
 355             connect_api()
 360             recon=0
 365         endif
 370     endif
 375     cls
    
 380     print ltb$
 385     print "                S.P.O.T. — ";ltb$;"S";bl$;"atellite ";ltb$;
 390     print "P";bl$;"osition and ";ltb$;"O";bl$;"rbital ";ltb$;"T";
 395     print bl$;"racking"
 400     for n=1 to 56
 405         print 
 410     next
 415     print "                  Latitude ";ltb$;lat#,
 420     print bl$;"  Longitude ";ltb$;lon#
 425     x=int((lon#+180)/360*319+0.5)
 430     y=int((90-lat#)/180*239+0.5)
 435     pl_counter=pl_counter+1
 440     if pl_counter>5
 445         pl_counter=0
 450         line color 10 x,y to x,y
 455     endif
 460     sprite 0 image 0 to x,y
 465     q$=inkey$()
 470     if (q$<>"") & (q$<>"q")
 475         print rd$"                             PRESS Q TO EXIT PROGRAM";
 480     endif
 485     if q$="q"
 490         print rd$"                             EXITING PROGRAM";
 495     else
 500         delay(100000) 
 505     endif
 510 until q$="q"

 515 ' Clean up and exit
 520 cursor on
 525 bitmap off
 530 sprites off
 535 cls
 540 print rd$;"PROGRAM TERMINATED"
 545 end

 550 ' --- PROCEDURES ---
 555 proc initialize()
 560     ' Send initialization commands to the WIZFi module
 565     repeat
 570         read a$
 575         if a$<>"stop" 
 580             sendcommand(a$)
 585             delay(10000)
 590             readresponse()
 595         endif
 600     until a$="stop"
 605 endproc

 610 proc connect()
 615     ' Connect to WiFi
 620     print "CONNECTING TO WIFI..."
 625     print "IF ALREADY CONNECTED, PRESS ENTER."
 630     print
 635     print "Enter WIFI ID: ";
 640     input wifi_id$
 645     if wifi_id$<>""
 650         print "Enter WIFI password: ";
 655         input wifi_pass$
 660         cmd$ = "AT+CWJAP_CUR='"+wifi_id$+"','"+wifi_pass$+"'"
 665         sendcommand(cmd$)
 670         delay(50000)
 675         silentread()
 680     endif
 685     sendcommand("AT+CIPSTA_CUR?")
 690     delay(50000)
 695     readresponse()
 700 endproc

 705 proc connect_api()
 710     ' Connect to the API server for iss position data
 715     sendcommand("AT+CIPSTART='TCP','api.open-notify.org',80")
 720     delay(50000)
 725     readresponse()
 730 endproc

 735 proc sendcommand(cmd$)
 740     ' Send a command to the WIZFi module
 745     poke k2_leds, peek(k2_leds)|64
 750     for n=1 to len(cmd$)
 755         pokel ntwk_rgb, $0000ff
 760         b=asc(mid$(cmd$,n,1))
 765         if b=39 then b=34 
 770         pokel ntwk_rgb, $000000
 775         poke wiz_data, b
 780     next
 785     poke wiz_data, 13 
 790     poke wiz_data, 10
 795     poke k2_leds, peek(k2_leds) & $bf
 800 endproc

 805 proc readresponse()
 810     ' Read the response from the WIZFi module and 
 815     ' print it to the screen
 820     poke k2_leds, peek(k2_leds)|64
 825     while peek(wiz_fifo)<>0
 830         pokel ntwk_rgb, $ff0000
 835         b=peek(wiz_data)
 840         pokel ntwk_rgb, $000000
 845         print chr$(b);
 850     wend
 855     poke k2_leds, peek(k2_leds) & $bf
 860 endproc

 865 proc silentread()
 870     ' Read the response from the WIZFi module 
 875     ' without printing it to the screen
 880     poke k2_leds, peek(k2_leds)|64
 885     while peek(wiz_fifo)<>0
 890         pokel ntwk_rgb, $ff0000
 895         b=peek(wiz_data)
 900         pokel ntwk_rgb, $000000
 905     wend
 910     poke k2_leds, peek(k2_leds) & $bf
 915 endproc

 920 proc getdata()
 925     ' Read the data from the API response and
 930     ' extract the latitude and longitude
 935     poke k2_leds, peek(k2_leds)|64
 940     bf$="12345":gd=0:lgth$=""
 945     lt$=chr$(34)+"latitude"+chr$(34)+": "+chr$(34)
 950     ln$=chr$(34)+"longitude"+chr$(34)+": "+chr$(34) 
 955     lat$="":lon$=""
 960     while peek(wiz_fifo)<>0
 965         pokel ntwk_rgb, $ff0000
 970         b=peek(wiz_data)
 975         if gd=1
 980             if chr$(b)=":"
 985                 gd=2
 990                 lgth=val(lgth$)
 995                 latlon=0
1000                 bf$="12345678901234"
1005             else
1010                 lgth$=lgth$+chr$(b)
1015             endif
1020         endif
1025         if gd=0
1030             bf$=right$(bf$+chr$(b),5)
1035             if bf$="+IPD," then gd=1
1040         endif
1045         if gd=2
1050             for n=1 to lgth
1055                 b=peek(wiz_data)
1060                 pokel ntwk_rgb, $ff0000
1065                 bf$=bf$+chr$(b)
1070                 bf$=right$(bf$,15)
1075                 if latlon = 0
1080                      if right$(bf$,13)=lt$ then latlon=1
1085                      if right$(bf$,14)=ln$ then latlon=2
1090                 else
1095                     if latlon=1
1100                         if b=34
1105                             latlon=0
1110                         else 
1115                             lat$=lat$+chr$(b)
1120                         endif
1125                     endif
1130                     if latlon=2
1135                         if b=34
1140                             latlon=0
1145                         else 
1150                             lon$=lon$+chr$(b)
1155                         endif
1160                     endif
1165                 endif
1170                 pokel ntwk_rgb, $000000
1175             next
1180             gd=4
1185         endif
1190         pokel ntwk_rgb, $000000
1195     wend
1200     poke k2_leds, peek(k2_leds) & $bf
1205 endproc

1210 proc makesprite()
1215     ' Create a sprite for the ISS icon
1220     for n=0 to 259
1225         read b
1230         poke $7800+n, b
1235     next
1240     memcopy $7800, 260 to $30000
1245 endproc

1250 proc drawmap()
1255     ' Draw the world map using the coastline data
1260     cls
1265     while ln<>888
1270         read ln,lt
1275         if ln <> 888
1280             if ln=999
1285                 read ln,lt
1290                 x=int((ln+180)/360*319+0.5)
1295                 y=int((90-lt)/180*239+0.5)
1300                 plot x,y 
1305             else
1310                 x=int((ln+180)/360*319+0.5)
1315                 y=int((90-lt)/180*239+0.5)
1320                 line color 40 to x,y
1325             endif
1330         endif
1335     wend
1340 endproc

1345 proc delay(count)
1350     ' Simple delay loop to waste time
1355     for i=1 to count
1360         ' do nothing, just waste time
1365     next
1370 endproc

1375 ' control commands to initialize the module
1380 data "AT+GMR"
1385 data "AT+UART_CUR?"
1390 data "AT+CWMODE_CUR=1"
1395 data "AT+CWMODE_CUR?"
1400 data "AT+CIPMUX=0"
1405 data "stop"

1410 ' sprite data for the ISS icon
1415 data $11,$1,$0
1420 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1425 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1430 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1435 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1440 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1445 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1450 data $0,$b,$0,$b,$0,$0,$0,$b,$0,$0,$0,$b,$0,$b,$0,$0
1455 data $0,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$0,$0
1460 data $0,$b,$0,$b,$0,$0,$0,$b,$0,$0,$0,$b,$0,$b,$0,$0
1465 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1470 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1475 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1480 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1485 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1490 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1495 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1500 data $80

1505 ' GLOBAL COASTLINE DATA 
1510 ' =========================================

1515 ' --- NORTH AMERICA ------------------------
1520 data 999,999
1525 data -124,48,-123,39,-117,32,-110,24,-109,23,-110,24
1530 data -114,30,-114,31,-105,21,-105,20,-97,15,-94,16
1535 data -91,14,-88,13,-84,9,-80,7,-79,8,-77,7,-77,8
1540 data -80,8,-82,10,-84,12,-83,15,-88,16,-87,21,-89,22
1545 data -91,21,-91,19,-95,18,-98,22,-97,26,-97,28,-94,30
1550 data -90,29,-88,30,-84,30,-82,26,-80,25,-80,28,-82,31
1555 data -80,33,-76,35,-75,38,-72,41,-68,45,-63,45,-65,47
1560 data -63,50,-54,47,-53,49,-65,61,-67,59,-75,63,-78,62
1565 data -79,52,-80,52,-83,55,-94,59,-85,67,-114,69,-143,70
1570 data -158,71,-167,68,-165,60,-158,59,-159,57,-169,53
1575 data -159,56,-151,60,-139,59,-131,53,-124,48

1580 data 999,999
1585 data -78,64,-74,64,-70,62,-65,62,-62,67,-77,74,-86,74
1590 data -90,72,-86,68,-85,66,-87,64,-85,63,-82,64,-83,66
1595 data -80,70,-72,68,-75,66,-77,65,-78,64

1600 data 999,999
1605 data -61,83,-81,75,-90,75,-114,75,-123,76,-98,80,-77,83,-61,83

1610 data 999,999
1615 data -124,74,-125,72,-122,71,-119,72,-117,69,-109,69
1620 data -106,69,-102,68,-92,70,-97,74,-103,73,-105,74
1625 data -111,73,-118,74,-124,74

1630 ' --- SOUTH AMERICA ------------------------
1635 data 999,999
1640 data -78,7,-77,4,-78,0,-81,-5,-76,-15,-70,-19,-72,-31
1645 data -71,-33,-74,-40,-76,-49,-74,-53,-71,-55,-67,-55
1650 data -64,-54,-68,-53,-68,-50,-62,-40,-52,-32,-47,-25
1655 data -42,-23,-39,-17,-39,-13,-34,-8,-35,-5,-46,-1
1660 data -50,2,-52,6,-57,6,-62,11,-69,12,-75,11,-78,7

1665 ' --- EUROPE -------------------------------
1670 data 999,999
1675 data 31,70,26,71,14,68,10,64,5,62,6,59,7,58,11,59,13,57
1680 data 9,57,7,53,1,49,-5,48,-1,46,-2,43,-9,44,-9,37
1685 data -2,37,4,43,10,44,13,41,16,39,16,39,18,40,13,44
1690 data 13,46,19,42,20,39,23,38,24,40,28,42,31,46,38,47

1695 data 999,999
1700 data 0,54,-2,56,-3,59,-6,58,-3,54,-5,50,0,51,2,53,0,54

1705 data 999,999
1710 data -10,54,-10,52,-7,52,-6,54,-8,55,-10,54

1715 data 999,999
1720 data 25,66,21,65,17,61,18,59,16,56,12,55,14,54,21,56
1725 data 23,59,28,60,28,61,21,60,19,60,25,66

1730 ' --- AFRICA -------------------------------
1735 data 999,999
1740 data -13,28,-17,21,-17,12,-8,4,3,6,9,3,14,-10
1745 data 12,-19,19,-34,27,-34,35,-23,36,-18,41,-15
1750 data 39,-7,43,0,49,7,52,12,45,10,38,17,34,27
1755 data 32,31,21,33,19,30,10,34,10,37,0,37,-9,33
1760 data -13,28

1765 ' --- ASIA --------------------------------
1770 data 999,999
1775 data 38,47,38,45,42,42,40,41,33,42,27,40,28,37
1780 data 33,36,37,37,34,31,33,31,34,28,35,27,43,17
1785 data 44,12,52,16,60,22,56,25,56,26,54,24,51,25
1790 data 48,29,49,30,52,28,55,26,57,27,58,25,67,25
1795 data 70,21,73,20,75,14,77,8,80,12,80,16,87,20
1800 data 88,22,92,23,95,16,97,17,99,12,105,9,109,12
1805 data 109,15,105,19,108,22,115,23,120,26,122,30
1810 data 118,39,121,40,126,38,126,34,129,36,129,38
1815 data 127,40,135,44,140,49,141,54,136,55,145,59
1820 data 154,60,164,62,159,58,155,56,157,51,178,64
1825 data 170,66,174,70,132,70,102,77,68,69,43,66,31,70

1830 ' --- AUSTRALIA ----------------------------
1835 data 999,999
1840 data 121,-20,115,-21,113,-24,115,-31,115,-35
1845 data 119,-35,127,-32,134,-32,142,-38,149,-38
1850 data 153,-31,151,-23,146,-19,143,-12,142,-11
1855 data 141,-18,135,-15,137,-12,131,-12,129,-15
1860 data 125,-14,123,-17,121,-20

1865 ' --- GREENLAND ----------------------------
1870 data 999,999
1875 data -37,65,-31,68,-26,69,-21,70,-18,75,-19,79
1880 data -11,82,-33,84,-60,82,-72,78,-68,76,-60,76
1885 data -53,66,-49,61,-44,60,-41,63,-40,65,-37,65

1890 ' --- ANTARCTICA ---------------------------
1895 data 999,999
1900 data 179,-78,165,-76,168,-74,171,-72,165,-70
1905 data 138,-66,113,-66,83,-66,76,-69,58,-66
1910 data 46,-67,12,-70,-10,-70,-25,-74,-42,-78
1915 data -59,-75,-61,-66,-56,-63,-65,-66,-76,-73
1920 data -101,-72,-103,-75,-126,-73,-148,-75
1925 data -162,-78,-179,-78

1930 ' --- SMALL ISLANDS -------------------------
1935 data 999,999
1940 data 142,45,139,39,134,36,129,33,130,30,135,34
1945 data 141,36,142,45

1950 data 999,999
1955 data 151,-10,145,-4,138,-1,132,-3,141,-9,151,-10

1960 data 999,999
1965 data 98,13,99,8,102,2,98,4,95,5,105,-7,120,-9
1970 data 126,-8,112,-7,106,-5,103,1,105,1,103,6
1975 data 100,8,96,14,98,13

1980 data 999,999
1985 data 109,1,111,-3,116,-4,118,2,118,6,117,8,114,4,109,1

1990 data 999,999
1995 data -18,63,-13,65,-16,67,-20,66,-23,66,-24,65,-18,63

2000 data 888,888

2005 ' =========================================
2010 ' END DATA