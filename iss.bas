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
 310     silentread()
 315     sendcommand(link$)
 320     delay(10000)
 325     silentread()
 330     sendcommand(s$)
 335     delay(10000)
 340     getdata()
 345     if (lat$<>"")&(lon$<>"")
 350         lat#=val(lat$)
 355         lon#=val(lon$)
 360         ts=val(tms$)
 365         hh=ts\3600
 370         hh=hh%24
 375         mm=ts\60
 380         mm=mm%60
 385         ss=ts%60
 390     else
 395         recon=recon+1
 400         if recon>1
 405             print at 20,28; rd$;"RECONNECTION ATTEMPT"
 410             connect_api()
 415             recon=0
 420         endif
 425     endif
 430     cls
    
 435     print ltb$
 440     print "                S.P.O.T. — ";ltb$;"S";bl$;"atellite ";ltb$;
 445     print "P";bl$;"osition and ";ltb$;"O";bl$;"rbital ";ltb$;"T";
 450     print bl$;"racking"
 455     print at 57,20; "UTC Time: ";ltb$;hh;":";
 460     if mm<10 then print "0";
 465     print mm;":";
 470     if ss<10 then print "0";
 475     print ss
 480     print at 56,45; bl$;"Latitude  ";ltb$;lat#
 485     print at 57,45; bl$;"Longitude ";ltb$;lon#
 490     x=int((lon#+180)/360*319+0.5)
 495     y=int((90-lat#)/180*239+0.5)
 500     pl_counter=pl_counter+1
 505     if pl_counter>5
 510         pl_counter=0
 515         line color 10 x,y to x,y
 520     endif
 525     sprite 0 image 0 to x,y
 530     q$=inkey$()
 535     if (q$<>"") & (q$<>"q")
 540         print at 20,28; rd$"PRESS Q TO EXIT PROGRAM";
 545     endif
 550     if q$="q"
 555         print at 21,28; rd$"EXITING PROGRAM";
 560     else
 565         delay(100000) 
 570     endif
 575 until q$="q"

 580 ' Clean up and exit
 585 cursor on
 590 bitmap off
 595 sprites off
 600 cls
 605 print rd$;"PROGRAM TERMINATED"
 610 end

 615 ' --- PROCEDURES ---
 620 proc initialize()
 625     ' Send initialization commands to the WIZFi module
 630     repeat
 635         read a$
 640         if a$<>"stop" 
 645             sendcommand(a$)
 650             delay(10000)
 655             readresponse()
 660         endif
 665     until a$="stop"
 670 endproc

 675 proc connect()
 680     ' Connect to WiFi
 685     poke ip_status, 0
 690     print "CONNECTING TO WIFI..."
 695     print "IF ALREADY CONNECTED, PRESS ENTER."
 700     print
 705     print "Enter WIFI ID: ";
 710     input wifi_id$
 715     if wifi_id$<>""
 720         print "Enter WIFI password: ";
 725         input wifi_pass$
 730         repeat
 735             cmd$ = "AT+CWJAP_CUR='"+wifi_id$+"','"+wifi_pass$+"'"
 740             sendcommand(cmd$)
 745             delay(50000)
 750             readresponse()
 755         until peek(ip_status)=1
 760     endif
 765     sendcommand("AT+CIPSTA_CUR?")
 770     delay(50000)
 775     readresponse()
 780 endproc

 785 proc connect_api()
 790     ' Connect to the API server for iss position data
 795     while peek(wiz_fifo)<>0
 800         readresponse()
 805         delay(5000)
 810     wend
 815     sendcommand("AT+CIPSTART='TCP','api.open-notify.org',80")
 820     delay(50000)
 825     readresponse()
 830 endproc

 835 proc sendcommand(cmd$)
 840     ' Send a command to the WIZFi module
 845     poke k2_leds, peek(k2_leds)|64
 850     for n=1 to len(cmd$)
 855         pokel ntwk_rgb, $0000ff
 860         b=asc(mid$(cmd$,n,1))
 865         if b=39 then b=34 
 870         pokel ntwk_rgb, $000000
 875         poke wiz_data, b
 880     next
 885     poke wiz_data, 13 
 890     poke wiz_data, 10
 895     poke k2_leds, peek(k2_leds) & $bf
 900 endproc

 905 proc readresponse()
 910     ' Read the response from the WIZFi module and 
 915     ' print it to the screen
 920     r$="0123456789"
 925     poke k2_leds, peek(k2_leds)|64
 930     while peek(wiz_fifo)<>0
 935         pokel ntwk_rgb, $ff0000
 940         b=peek(wiz_data)
 945         pokel ntwk_rgb, $000000
 950         print chr$(b);
 955         r$=right$(r$+chr$(b),10)
 960         if right$(r$,5)="+IPD," then dump()
 965         if right$(r$,2)="OK" then poke wizfi_status, 1
 970         if right$(r$,4)="FAIL" then poke wizfi_status, 9
 975         if right$(r$,5)="ERROR" then poke wizfi_status, 8
 980         if right$(r$,9)="busy p..." then poke wizfi_status, 2
 985         if right$(r$,6)="GOT IP" then poke ip_status, 1
 990     wend
 995     poke k2_leds, peek(k2_leds) & $bf
1000 endproc

1005 proc silentread()
1010     ' Read the response from the WIZFi module 
1015     ' without printing it to the screen
1020     r$="0123456789"
1025     poke k2_leds, peek(k2_leds)|64
1030     while peek(wiz_fifo)<>0
1035         pokel ntwk_rgb, $ff0000
1040         b=peek(wiz_data)
1045         pokel ntwk_rgb, $000000
1050         r$=right$(r$+chr$(b),10)
1055         if right$(r$,5)="+IPD," then dump()
1060         if right$(r$,2)="OK" then poke wizfi_status, 1
1065         if right$(r$,4)="FAIL" then poke wizfi_status, 9
1070         if right$(r$,5)="ERROR" then poke wizfi_status, 8
1075         if right$(r$,9)="busy p..." then poke wizfi_status, 2
1080         if right$(r$,6)="GOT IP" then poke ip_status, 1
1085     wend
1090     poke k2_leds, peek(k2_leds) & $bf
1095 endproc
 
1100 proc dump()
1105     ' Dump the data from the WIZFi module when an 
1110     ' +IPD response is received when not expected
1115     ' to clear the buffer and prevent overflow
1120     state=1:lgth$="":lgth=0
1125     while peek(wiz_fifo)>0
1130         pokel ntwk_rgb, $ff0000
1135         b=peek(wiz_data)
1140         if state=1
1145             if chr$(b)=":"
1150                 state=2
1155                 lgth=val(lgth$)
1160             else
1165                 lgth$=lgth$+chr$(b)
1170             endif
1175         endif
1180         if state=2
1185             for n=1 to lgth
1190                 pokel ntwk_rgb, $00ff00
1195                 b=peek(wiz_data)
1200                 pokel ntwk_rgb, $000000
1205             next
1210             state=0
1215         endif
1220         pokel ntwk_rgb, $000000
1225     wend
1230 endproc

1235 proc getdata()
1240     ' Read the data from the API response and
1245     ' extract the latitude and longitude
1250     poke k2_leds, peek(k2_leds)|64
1255     bf$="12345678901234567":state=0:lgth$=""
1260     lt$=chr$(34)+"latitude"+chr$(34)+": "+chr$(34)
1265     ln$=chr$(34)+"longitude"+chr$(34)+": "+chr$(34) 
1270     ts$=chr$(34)+"timestamp"+chr$(34)+": "
1275     lat$="":lon$="":clen$="":tms$=""
1280     ct$="Content-Length: ":ct=0
1285     do_count=0
1290     rnlf$=chr$(13)+chr$(10)+chr$(13)+chr$(10)
1295     repeat
1300         while peek(wiz_fifo)>0
1305             pokel ntwk_rgb, $ff0000
1310             b=peek(wiz_data)
1315             if state=1
1320                 if chr$(b)=":"
1325                     state=2
1330                     lgth=val(lgth$)
1335                     latlon=0
1340                 else
1345                     lgth$=lgth$+chr$(b)
1350                 endif
1355             endif
1360             if state=0
1365                 bf$=right$(bf$+chr$(b),20)
1370                 if right$(bf$,5)="+IPD," then state=1
1375             endif
1380             if state=2
1385                 for n=1 to lgth
1390                     if do_count=1 then ct=ct-1
1395                     b=peek(wiz_data)
1400                     pokel ntwk_rgb, $ff0000
1405                     bf$=bf$+chr$(b)
1410                     bf$=right$(bf$,16)
1415                     if latlon = 0
1420                          if right$(bf$,13)=lt$ then latlon=1
1425                          if right$(bf$,14)=ln$ then latlon=2
1430                          if right$(bf$,13)=ts$ then latlon=3
1435                          if right$(bf$,15)=ct$ then latlon=4
1440                     else
1445                         if latlon=1
1450                             if b=34
1455                                 latlon=0
1460                             else 
1465                                 lat$=lat$+chr$(b)
1470                             endif
1475                         endif
1480                         if latlon=2
1485                             if b=34
1490                                 latlon=0
1495                             else 
1500                                 lon$=lon$+chr$(b)
1505                             endif
1510                         endif
1515                         if latlon=3
1520                             if (b<48)|(b>57)
1525                                 latlon=0
1530                             else 
1535                                 tms$=tms$+chr$(b)
1540                             endif
1545                         endif
1550                         if latlon=4
1555                             if b=13
1560                                 latlon=5
1565                                 ct=val(clen$)
1570                             else 
1575                                 clen$=clen$+chr$(b)
1580                             endif
1585                         endif
1590                         if latlon=5
1595                             if right$(bf$,4)=rnlf$
1600                                 do_count=1
1605                                 latlon=0
1610                             endif
1615                         endif
1620                     endif
1625                     pokel ntwk_rgb, $000000
1630                 next
1635                 state=4
1640             endif
1645             pokel ntwk_rgb, $000000
1650         wend
1655     until ct<1
1660     poke k2_leds, peek(k2_leds) & $bf
1665 endproc

1670 proc makesprite()
1675     ' Create a sprite for the ISS icon
1680     for n=0 to 259
1685         read b
1690         poke $7800+n, b
1695     next
1700     memcopy $7800, 260 to $30000
1705 endproc

1710 proc drawmap()
1715     ' Draw the world map using the coastline data
1720     cls
1725     while ln<>888
1730         read ln,lt
1735         if ln <> 888
1740             if ln=999
1745                 read ln,lt
1750                 x=int((ln+180)/360*319+0.5)
1755                 y=int((90-lt)/180*239+0.5)
1760                 plot x,y 
1765             else
1770                 x=int((ln+180)/360*319+0.5)
1775                 y=int((90-lt)/180*239+0.5)
1780                 line color 40 to x,y
1785             endif
1790         endif
1795     wend
1800 endproc

1805 proc delay(count)
1810     ' Simple delay loop to waste time
1815     for i=1 to count
1820         ' do nothing, just waste time
1825     next
1830 endproc


1835 ' sprite data for the ISS icon
1840 data $11,$1,$0
1845 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1850 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1855 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1860 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1865 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1870 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1875 data $0,$8,$0,$8,$0,$0,$0,$b,$0,$0,$0,$8,$0,$8,$0,$0
1880 data $0,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$b,$0,$0
1885 data $0,$8,$0,$8,$0,$0,$0,$b,$0,$0,$0,$8,$0,$8,$0,$0
1890 data $0,$b,$0,$b,$0,$0,$b,$b,$b,$0,$0,$b,$0,$b,$0,$0
1895 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1900 data $0,$b,$0,$b,$0,$0,$0,$0,$0,$0,$0,$b,$0,$b,$0,$0
1905 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1910 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1915 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1920 data $0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
1925 data $80

1930 ' GLOBAL COASTLINE DATA 
1935 ' =========================================

1940 ' --- NORTH AMERICA ------------------------
1945 data 999,999
1950 data -124,48,-123,39,-117,32,-110,24,-109,23,-110,24
1955 data -114,30,-114,31,-105,21,-105,20,-97,15,-94,16
1960 data -91,14,-88,13,-84,9,-80,7,-79,8,-77,7,-77,8
1965 data -80,8,-82,10,-84,12,-83,15,-88,16,-87,21,-89,22
1970 data -91,21,-91,19,-95,18,-98,22,-97,26,-97,28,-94,30
1975 data -90,29,-88,30,-84,30,-82,26,-80,25,-80,28,-82,31
1980 data -80,33,-76,35,-75,38,-72,41,-68,45,-63,45,-65,47
1985 data -63,50,-54,47,-53,49,-65,61,-67,59,-75,63,-78,62
1990 data -79,52,-80,52,-83,55,-94,59,-85,67,-114,69,-143,70
1995 data -158,71,-167,68,-165,60,-158,59,-159,57,-169,53
2000 data -159,56,-151,60,-139,59,-131,53,-124,48

2005 data 999,999
2010 data -78,64,-74,64,-70,62,-65,62,-62,67,-77,74,-86,74
2015 data -90,72,-86,68,-85,66,-87,64,-85,63,-82,64,-83,66
2020 data -80,70,-72,68,-75,66,-77,65,-78,64

2025 data 999,999
2030 data -61,83,-81,75,-90,75,-114,75,-123,76,-98,80,-77,83,-61,83

2035 data 999,999
2040 data -124,74,-125,72,-122,71,-119,72,-117,69,-109,69
2045 data -106,69,-102,68,-92,70,-97,74,-103,73,-105,74
2050 data -111,73,-118,74,-124,74

2055 ' --- SOUTH AMERICA ------------------------
2060 data 999,999
2065 data -78,7,-77,4,-78,0,-81,-5,-76,-15,-70,-19,-72,-31
2070 data -71,-33,-74,-40,-76,-49,-74,-53,-71,-55,-67,-55
2075 data -64,-54,-68,-53,-68,-50,-62,-40,-52,-32,-47,-25
2080 data -42,-23,-39,-17,-39,-13,-34,-8,-35,-5,-46,-1
2085 data -50,2,-52,6,-57,6,-62,11,-69,12,-75,11,-78,7

2090 ' --- EUROPE -------------------------------
2095 data 999,999
2100 data 31,70,26,71,14,68,10,64,5,62,6,59,7,58,11,59,13,57
2105 data 9,57,7,53,1,49,-5,48,-1,46,-2,43,-9,44,-9,37
2110 data -2,37,4,43,10,44,13,41,16,39,16,39,18,40,13,44
2115 data 13,46,19,42,20,39,23,38,24,40,28,42,31,46,38,47

2120 data 999,999
2125 data 0,54,-2,56,-3,59,-6,58,-3,54,-5,50,0,51,2,53,0,54

2130 data 999,999
2135 data -10,54,-10,52,-7,52,-6,54,-8,55,-10,54

2140 data 999,999
2145 data 25,66,21,65,17,61,18,59,16,56,12,55,14,54,21,56
2150 data 23,59,28,60,28,61,21,60,19,60,25,66

2155 ' --- AFRICA -------------------------------
2160 data 999,999
2165 data -13,28,-17,21,-17,12,-8,4,3,6,9,3,14,-10
2170 data 12,-19,19,-34,27,-34,35,-23,36,-18,41,-15
2175 data 39,-7,43,0,49,7,52,12,45,10,38,17,34,27
2180 data 32,31,21,33,19,30,10,34,10,37,0,37,-9,33
2185 data -13,28

2190 ' --- ASIA --------------------------------
2195 data 999,999
2200 data 38,47,38,45,42,42,40,41,33,42,27,40,28,37
2205 data 33,36,37,37,34,31,33,31,34,28,35,27,43,17
2210 data 44,12,52,16,60,22,56,25,56,26,54,24,51,25
2215 data 48,29,49,30,52,28,55,26,57,27,58,25,67,25
2220 data 70,21,73,20,75,14,77,8,80,12,80,16,87,20
2225 data 88,22,92,23,95,16,97,17,99,12,105,9,109,12
2230 data 109,15,105,19,108,22,115,23,120,26,122,30
2235 data 118,39,121,40,126,38,126,34,129,36,129,38
2240 data 127,40,135,44,140,49,141,54,136,55,145,59
2245 data 154,60,164,62,159,58,155,56,157,51,178,64
2250 data 170,66,174,70,132,70,102,77,68,69,43,66,31,70

2255 ' --- AUSTRALIA ----------------------------
2260 data 999,999
2265 data 121,-20,115,-21,113,-24,115,-31,115,-35
2270 data 119,-35,127,-32,134,-32,142,-38,149,-38
2275 data 153,-31,151,-23,146,-19,143,-12,142,-11
2280 data 141,-18,135,-15,137,-12,131,-12,129,-15
2285 data 125,-14,123,-17,121,-20

2290 ' --- GREENLAND ----------------------------
2295 data 999,999
2300 data -37,65,-31,68,-26,69,-21,70,-18,75,-19,79
2305 data -11,82,-33,84,-60,82,-72,78,-68,76,-60,76
2310 data -53,66,-49,61,-44,60,-41,63,-40,65,-37,65

2315 ' --- ANTARCTICA ---------------------------
2320 data 999,999
2325 data 179,-78,165,-76,168,-74,171,-72,165,-70
2330 data 138,-66,113,-66,83,-66,76,-69,58,-66
2335 data 46,-67,12,-70,-10,-70,-25,-74,-42,-78
2340 data -59,-75,-61,-66,-56,-63,-65,-66,-76,-73
2345 data -101,-72,-103,-75,-126,-73,-148,-75
2350 data -162,-78,-179,-78

2355 ' --- SMALL ISLANDS -------------------------
2360 data 999,999
2365 data 142,45,139,39,134,36,129,33,130,30,135,34
2370 data 141,36,142,45

2375 data 999,999
2380 data 151,-10,145,-4,138,-1,132,-3,141,-9,151,-10

2385 data 999,999
2390 data 98,13,99,8,102,2,98,4,95,5,105,-7,120,-9
2395 data 126,-8,112,-7,106,-5,103,1,105,1,103,6
2400 data 100,8,96,14,98,13

2405 data 999,999
2410 data 109,1,111,-3,116,-4,118,2,118,6,117,8,114,4,109,1

2415 data 999,999
2420 data -18,63,-13,65,-16,67,-20,66,-23,66,-24,65,-18,63

2425 data 888,888

2430 ' control commands to initialize the module
2435 data "AT+GMR"
2440 data "AT+UART_CUR?"
2445 data "AT+CWMODE_CUR=1"
2450 data "AT+CWMODE_CUR?"
2455 data "AT+CIPMUX=0"
2460 data "AT+CIPSTA_CUR?"
2465 data "stop"

2470 ' =========================================
2475 ' END DATA