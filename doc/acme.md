# ACME Build & Package Management

Az ACME egy CMake script library, amely C/C++ fejlesztést, karbantartást és kooperációt támogatja azzal, hogy

- a fejlesztők a *boilerplate* scriptek/kódok írása helyett a tényleges kódolással foglalkozhatnak
- segíti a projektek kisebb egységekre bontását és azok összekapcsolását, a fejlesztők együttműködését, a source-ok fizikai elrendezését (scm, könyvtárszerkezet)


## Large-scale C/C++ fejlesztés problémái

Még egy új, üres C++ library projekt indítása is sok munkával jár. Egy CMake config modul írásával együtt 10-20 perc is eltelhet,  amíg hozzákezdhetünk a tényleges fejlesztéshez. Holott az egész inicializálási folyamatot elvégezhetné a automatikusan a számítógép. 

Erthető, hogy a fejlesztők szeretik megspórolni ezt a munkát. Ennek eredménye:

- Túlzsúfolt, nem összetartozó funkciókat tartalmazó, monolitikus projektek
- Ahogy fejlődik a kód, nehéz az általános részek kifaktorizálása, rossz a kódújrafelhasználás hatékonysága, copy-paste programozás
- Megállapodások hiánya miatt csapatok között nehezebb egymás kódját felhasználni (függőségek kezelése)

A CMake framework nagy segítség, de még így is sok, ismétlődő tevékenységet kell végezni. Az ACME ezek automatizálásában segít.  

## Bevezető az ACME használatába (példa)

Az ACME egyetlen könyvtárból álló CMake script gyűjtemény. Az inicializáló scriptet akkor futtatjuk, amikor új projektek indítunk. A többi script felinstallálódik a CMake projektünkbe és minden CMake generáláskor lefut, karbantartja a projektet.

Egy új projekt indítása a következő lépésekből áll:

- új C/C++ projekt könyvtárának, repójának létrehozása
- néhány source file létrehozása
- a project ACME-sítése. Elindítjuk az acme command line toolját: 

        acme init my_proj_dir -a -p kishonti.ng.myproj

Ez a parancs a `my_proj_dir`-ben levő projektet fogja inicializálni, statikus library buildelésére (`-a` kapcsoló), a `-p` kapcsoló pedig a package nevét állítja be

A parancs hatására a következő fileok és könyvtárak jönnek létre:

- `myproj/CMakeLists.txt`: automatikusan generált
- `myproj/acme.conf.cmake`: alapvető projekt beállítások
- `myproj/.acme` könyvtár, benne az ACME scriptek

A továbbiakban minden cmake configurálásnál lefutnak az ACME scriptek, amik a következő funkciókat végzik el:   

## Az ACME funkciói

Az ACME script könyvtár a következő, lazán összekapcsolódó, de egymást támogató funkciókat valósítja meg:

### A CMakeList-ekben végrehajtott funkcionalitás egy helyre koncentrálása, faktorizálása

A legtöbb projekt nagyon hasonló kódokat tartalmaz a CMakeList-ekben. Az ACME ezt a logikát koncentrálja egyetlen helyre, így ugyanazokat a funkciókat sokkal alaposabban lehet implementálni, mert csak egyszer kell (pl. config modul írása).

Ennek fontos folyománya, hogy az ACME-n végzett fejlesztések egyszerre az összes projektben rendelkezésre fognak állni.

### Java-szerű egységes package elnevezési séma (company.foo.bar): 

Minden könyvtárak és alkalmazásoknak a Java, Python, Go nyelvekből ismerős sémának megfelelő egyedi package neve van. Ez megkönnyíti az elhelyezést és a hivatkozásokat.

### CMakeLists.txt automatikus generálása

Az `acme init` lépés előállít egy teljes CMakeLists.txt-t és acme.conf.cmake filekoat. Ezeket a fejlesztő később tovább módosíthatja.

### Package beállítások kifaktorizálása az acme.conf.cmake fileba

Egyes fordítási beállítások, úgymint package név, target típus (könyvtár/alkalmazás) egy külön, egységes fileban találhatóak.

### Headerek

- a publikusnak jelölt headerek installálása (headerben elhelyezett `//#acme public header` vagy `/*#acme public header*/` megjegyzéssel)
- include guard generálása (CMakeList-be generált függvényhívással)
- `all.h`, a package összes publikus headerjét includáló header generálása (CMakeList-be generált függvényhívás, default ki van kommentezve)

### Source fileok

- source és header fileok automatikus összegyűjtése (lásd CMakeList, acme_add_files függvényhívás). Lehetőség van a hagyományos, fix filenevek használatára és globbingra is.
- a file-ok könyvtárszerkezet szerinti source group-okba rendezése (automatikus, a CMAKE_CURRENT_SOURCE_DIR és CMAKE_CURRENT_BINARY_DIR könyvtárakhoz relatív path alapján)

### Dependenciák

- `find_package` helyett `acme_find_package`, amely automatikusan felhasználja a <package>_INCLUDE_DIRS/LIBRARIES/DEFINITIONS változókat és hozzáadja a projekt dependenciáihoz az adott package-et (config modulba belegenerálja a megfelelő find_package és más beállításokat). Itt van lehetőség azt megadni, hogy az adott package PUBLIC vagy PRIVATE dependencia. Szintén itt lehet namespace aliasokat definiálni.

### Config-modul generálása

- dependenciákat is kezeli, megkülönböztetve publikust és privátot (shared library esetén csak a publikusat kell továbbadni)
- runtime függőségeket is kezeli (so, dll)
- executable-hoz is gyártódik (így lekérdezhetőek a runtime dependenciák)

### Namespace-ek

- package namespace-ek használatának megkönnyítése (az alábbi `//#` acme parancsok után cmake konfigurálási időben generálódik a megfelelő namespace vagy using namespace deklaráció):

        //package név: kishonti.some.lib
		//#{

		//itt a kishonti::some::lib namespace-ben vagyunk

        //#}

- namespace alias és using namespace-ek generálása global namespace-be

        acme_find_package(kishonti.some.lib1 ALIAS somelib)
        acme_find_package(kishonti.some.lib2 ALIAS .)
        ...
        //#.

        //itt a kishonti::some::lib1 namespace somelib-ként érhető el
        //a kishonti::some::lib2 pedig using-olva van

- ugyanez lokális namespace-el együtt

        acme_find_package(kishonti.some.lib1 ALIAS somelib)
        acme_find_package(kishonti.some.lib2 ALIAS .)
        ...
        //#{
        
        //itt a lokális namespace-ben vagyunk
        //a kishonti::some::lib1 namespace somelib-ként érhető el
        //a kishonti::some::lib2 pedig using-olva van
        //#}
        

### Targetek

- debug postfix beállítása

## Az ACME filozófiája

- Az ACME scriptek teljes egészében installálásra kerülnek a projektbe, így az önjáró marad. A projektben bármikor abba lehet hagyni az ACME használatát és a generált fileokkal továbbdolgozni
- Az ACME lightweight, az automatizmusoknak átláthatóaknak kell lenniük
- Könnyű átjárhatóság az ACME és non-ACME projektek között (CMake best practice-ok betartása)

## Az ACME bevezetésének lépései

Az ACME-t használatát egyetlen projekten is el lehet kezdeni, mivel a szabványos config-modul alapján kompatibilis a nem-ACME-s projektekkel

- ACME letöltése: [http://scm.kishonti.local/git/kishonti/acme.git](http://scm.kishonti.local/git/kishonti/acme.git)
- A csomag gyökerében az `acme` shell script segítségével lehet használni az acme cmake scriptjeit.
- Egyelőre az egyetlen command a `init`. Az `acme init` kiírja a parancs rövid leírását.
- Az `acme init` segítségével iniciálizáljuk a projektet.
- Ha  már van létező `CMakeLists.txt` file, akkor az `init` előtt nevezzük át. Utána pedig vezessük át a lényeges dolgokat a régi `CMakeLists.txt`-ből
- Innentől kezdve a projekt a szokásos `cmake`-módon használható


Az ACME scripteken még sok fejlesztenivaló van, a gyakorlat során fog kiderülni, hogy mikre van még szükség.  
